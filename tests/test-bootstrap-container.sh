#!/usr/bin/env bash
set -euo pipefail

readonly IMAGE="ubuntu:24.04"
# amd64 matches the CI runner and the amd64-only espanso .deb in setup.sh.
readonly PLATFORM="linux/amd64"
readonly CONTAINER_USER="tester"
readonly PII_PLACEHOLDER="Placeholder Name"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

usage() {
    cat <<EOF
Usage: $(basename "$0") [--private <path>]

Copies the tracked and untracked-but-not-ignored files of this repo into a
fresh ${IMAGE} container (${PLATFORM}) as ~/.dotfiles of a non-root user with
passwordless sudo, then runs without a TTY:
  1. bootstrap.sh (no URL)
  2. setup.sh --doctor (in a login zsh)
  3. bootstrap.sh again, which must create no symlinks and skip apt packages
Any non-zero exit fails the run.

Options:
  --private <path>  Also copy the private dotfiles repo at <path> (tracked and
                    untracked-but-not-ignored files only) to ~/.dotfiles-private.
                    Local runs only. Seeds ~/.claude/pii-denylist.txt with one
                    placeholder entry, since the private post-install.sh exits 1
                    on an empty denylist.
  -h, --help        Show this help.
EOF
}

die() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

private_src=""
while (($# > 0)); do
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        --private)
            (($# >= 2)) && [[ -n "$2" ]] || die "--private needs a path"
            private_src="$2"
            shift 2
            ;;
        *)
            usage >&2
            die "unknown argument: $1"
            ;;
    esac
done

if [[ -n "$private_src" ]]; then
    private_top="$(git -C "$private_src" rev-parse --show-toplevel 2>/dev/null)" ||
        die "not a git work tree: $private_src"
    private_src="$private_top"
fi

command -v docker >/dev/null || die "docker not found"

# A plain bind mount is unusable: ignored local/ symlinks
# point into the developer's private repo and dangle in the container, and a
# writable mount would let setup write into the host tree. Paths still listed
# by --cached but deleted in the work tree are skipped.
stage_repo() {
    local src="$1" dest="$2" path
    mkdir -p "$dest"
    git -C "$src" ls-files -z --cached --others --exclude-standard |
        while IFS= read -r -d '' path; do
            # An untracked nested repo is listed as "dir/". tar would copy it
            # whole, its .git and ignored files included.
            [[ "$path" == */ ]] && continue
            if [[ -e "$src/$path" || -L "$src/$path" ]]; then
                printf '%s\0' "$path"
            fi
        done |
        COPYFILE_DISABLE=1 tar -C "$src" --null -T - -cf - |
        tar -C "$dest" -xpf -
}

# Rooted in TMPDIR explicitly: macOS mktemp ignores TMPDIR otherwise. The
# default TMPDIR locations are shared with containers by Docker Desktop.
stage_dir="$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-container.XXXXXX")"
cleanup() {
    rm -rf "$stage_dir"
}
trap cleanup EXIT

stage_repo "$REPO_ROOT" "$stage_dir/public"
if [[ -n "$private_src" ]]; then
    stage_repo "$private_src" "$stage_dir/private"
fi

# On a non-amd64 Docker engine (Apple Silicon) qemu-user passes the host's
# arm64 /proc/cpuinfo through, and Homebrew dies on its grep for ssse3 there,
# although the emulated CPU is x86-64-v3.
readonly EMULATED_CPU_FLAGS="fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 syscall nx lm pni pclmulqdq ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm abm bmi1 avx2 bmi2"
cpuinfo_mount=()
engine_arch="$(docker version --format '{{.Server.Arch}}')"
if [[ "$engine_arch" != "amd64" ]]; then
    printf 'processor\t: 0\nvendor_id\t: GenuineIntel\nmodel name\t: QEMU emulated x86-64-v3\nflags\t\t: %s\n\n' \
        "$EMULATED_CPU_FLAGS" >"$stage_dir/cpuinfo"
    cpuinfo_mount=(-v "$stage_dir/cpuinfo:/proc/cpuinfo:ro")
fi

cat >"$stage_dir/run.sh" <<'EOF'
set -euo pipefail

# Expected in the second bootstrap run: setup.sh's summary and bootstrap.sh's
# apt skip. The lines carry ANSI color codes, so match plain substrings.
# IDEMPOTENT_APT is the tail of bootstrap.sh's apt skip line, ending in the
# last entry of APT_PACKAGES, since other skips also print "already
# installed". A change to that list fails here visibly.
readonly IDEMPOTENT_SYMLINKS="Symlinks: 0 created"
readonly IDEMPOTENT_APT="openssh-client already installed"
readonly SECOND_RUN_LOG="/tmp/bootstrap-second-run.log"

banner() {
    printf '\n==> %s\n' "$1"
}

banner "Image prep (root)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
# sudo is needed before the user exists. tzdata avoids a debconf prompt that
# can stall a TTY-less apt-get later (sudo drops DEBIAN_FRONTEND).
# ca-certificates ships on every real Ubuntu, so do not rely on it arriving as
# a Recommends of curl. curl, git, file, build-essential are left to bootstrap.sh.
apt-get install -y -qq --no-install-recommends sudo tzdata ca-certificates
useradd --create-home --shell /bin/bash "$CONTAINER_USER"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$CONTAINER_USER" >"/etc/sudoers.d/$CONTAINER_USER"
chmod 0440 "/etc/sudoers.d/$CONTAINER_USER"
user_home="/home/$CONTAINER_USER"
cp -a /stage/public "$user_home/.dotfiles"
if [[ -d /stage/private ]]; then
    cp -a /stage/private "$user_home/.dotfiles-private"
    mkdir -p "$user_home/.claude"
    printf '%s\n' "$PII_PLACEHOLDER" >"$user_home/.claude/pii-denylist.txt"
fi
chown -R -h "$CONTAINER_USER:$CONTAINER_USER" "$user_home"

# sudo -i gives the user's login environment and starts in their home.
banner "Phase 1/3: bootstrap.sh (first run)"
sudo -iu "$CONTAINER_USER" bash .dotfiles/bootstrap.sh

# A login zsh reads the linked ~/.zprofile, which puts Homebrew on PATH.
banner "Phase 2/3: setup.sh --doctor"
sudo -iu "$CONTAINER_USER" zsh -lc '.dotfiles/setup.sh --doctor'

banner "Phase 3/3: bootstrap.sh (second run)"
sudo -iu "$CONTAINER_USER" bash .dotfiles/bootstrap.sh 2>&1 | tee "$SECOND_RUN_LOG"
for expected in "$IDEMPOTENT_SYMLINKS" "$IDEMPOTENT_APT"; do
    grep -qF "$expected" "$SECOND_RUN_LOG" || {
        printf 'error: second run is not idempotent, missing "%s"\n' "$expected" >&2
        exit 1
    }
done

banner "All phases passed"
EOF

# bash as PID 1 ignores the forwarded SIGINT, so tini runs as PID 1 and
# signals the whole process group, which lets Ctrl-C stop a local run.
docker run --rm --init -e TINI_KILL_PROCESS_GROUP=1 \
    --platform "$PLATFORM" \
    -v "$stage_dir:/stage:ro" \
    ${cpuinfo_mount[@]+"${cpuinfo_mount[@]}"} \
    -e CONTAINER_USER="$CONTAINER_USER" \
    -e PII_PLACEHOLDER="$PII_PLACEHOLDER" \
    "$IMAGE" \
    bash /stage/run.sh
