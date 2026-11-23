#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR
readonly DOTFILES_PRIVATE="${HOME}/.dotfiles-private"
readonly SYMLINKS_CONF="${DOTFILES_DIR}/symlinks.conf"
readonly PACKAGES_DIR="${DOTFILES_DIR}/packages"
# A literal ~ as the replacement of a ${var/#$HOME/...} expansion is
# tilde-expanded back to $HOME by bash 5 but not by 3.2, a replacement taken
# from a variable is expanded by neither.
readonly HOME_ABBREV='~'
readonly ESPANSO_DEB_ARCH="amd64"
# Upstream's install steps for the Wayland .deb grant this to the espanso binary
readonly ESPANSO_WAYLAND_CAP="cap_dac_override+p"
readonly BREW_MAC_GUARD=" if OS.mac?"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

SYMLINKS_CREATED=0
SYMLINKS_SKIPPED=0
SYMLINKS_FAILED=0
SYMLINKS_EXCLUDED=0
PACKAGES_WARNED=0

DRY_RUN=0
FORCE=0
LINK_ONLY=0
PACKAGES_ONLY=0
DO_DOCTOR=0
DO_UNLINK=0
DO_UPDATE=0
INSTALL_ALL=0
declare -a CATEGORIES=()
declare -a SKIP_GROUPS=()
declare -a ONLY_GROUPS=()

log_info()    { printf "${BLUE}==>${NC} ${BOLD}%s${NC}\n" "$1"; }
log_success() { printf " ${GREEN}ok${NC} %s\n" "$1"; }
log_skip()    { printf " ${DIM}-- %s${NC}\n" "$1"; }
log_warn()    { printf " ${YELLOW}!!${NC} %s\n" "$1"; }
log_error()   { printf " ${RED}!!${NC} %s\n" "$1" >&2; }
log_header()  { printf "\n${BOLD}%s${NC}\n\n" "$1"; }

detect_platform() {
    case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
        darwin*) echo "macos" ;;
        linux*)
            if [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]]; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

brewfile_entries() {
    local platform="$1" line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^(brew|cask|mas)[[:space:]] ]] || continue
        if [[ "${line%%#*}" == *"$BREW_MAC_GUARD"* ]]; then
            [[ "$platform" == "macos" ]] || continue
            line="${line/"$BREW_MAC_GUARD"/}"
        fi
        printf '%s\n' "$line"
    done < "$2"
}

apt_list_entries() {
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        printf '%s\n' "$line"
    done < "$1"
}

show_help() {
    cat << 'EOF'
Usage: ./setup.sh [options] [categories...]

Options:
  -a, --all            Install all package categories
  -s, --skip GROUP     Skip symlink group (repeatable, see groups below)
  -o, --only GROUP     Only link these symlink groups (repeatable, mutually exclusive with --skip)
  -l, --link-only      Only create symlinks, skip packages
  -p, --packages-only  Only install packages, skip symlinks
  -d, --doctor         Check system health and symlink integrity
  -u, --unlink         Remove all managed symlinks
  -U, --update         Update Claude skills (git clones ff-only + private tarball skills)
  -n, --dry-run        Show what would be done without making changes
  -f, --force          Overwrite existing files and symlinks
  -h, --help           Show this help message

Package categories:
  core      Shell, git, tmux, plugin manager, history, navigation
  cli       Modern CLI replacements, JSON/YAML tools, viewers, monitors
  dev       Editor, runtimes, git and lint tooling
  extra     Benchmarks, code stats, document conversion, media, OCR, network and disk tools
  macos     Hammerspoon, Karabiner-Elements, espanso, CLI tools (macOS only)
  Full lists: packages/Brewfile.<category>, on Linux also packages/apt.<category>.txt

EOF

    if [[ -f "$SYMLINKS_CONF" ]]; then
        printf "Symlink groups (from symlinks.conf):\n"
        sed -n 's/^# @group \([a-zA-Z0-9_-]*\).*/  \1/p' "$SYMLINKS_CONF"
        printf "  espanso  (virtual, handled separately due to spaces in macOS path)\n"
    fi

    cat << 'EOF'

Examples:
  ./setup.sh                     # Interactive setup
  ./setup.sh --all               # Full setup
  ./setup.sh core cli            # Install core + cli, then create symlinks
  ./setup.sh --all --skip gpg    # Full setup, skip GPG symlinks
  ./setup.sh --only shell git ssh  # Only link shell, git, and SSH configs
  ./setup.sh --link-only         # Only create symlinks
  ./setup.sh --link-only --force # Replace existing files and symlinks, never directories
  ./setup.sh --doctor            # Check system health
  ./setup.sh --update            # Update Claude skills
  ./setup.sh --dry-run --all     # Preview full setup
EOF
}

parse_args() {
    local -a valid_groups=(espanso)
    if [[ -f "$SYMLINKS_CONF" ]]; then
        while IFS= read -r _g; do
            valid_groups+=("$_g")
        done < <(sed -n 's/^# @group \([a-zA-Z0-9_-]*\).*/\1/p' "$SYMLINKS_CONF")
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--all)            INSTALL_ALL=1 ;;
            -l|--link-only)      LINK_ONLY=1 ;;
            -p|--packages-only)  PACKAGES_ONLY=1 ;;
            -d|--doctor)         DO_DOCTOR=1 ;;
            -u|--unlink)         DO_UNLINK=1 ;;
            -U|--update)         DO_UPDATE=1 ;;
            -s|--skip)
                if [[ $# -lt 2 || "$2" == -* ]]; then
                    log_error "--skip requires at least one group name"
                    exit 1
                fi
                shift
                while [[ $# -gt 0 && "$1" != -* ]]; do
                    local _lower
                    _lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
                    if [[ ${#valid_groups[@]} -gt 0 ]]; then
                        local _found=0
                        for _g in "${valid_groups[@]}"; do
                            [[ "$_g" == "$_lower" ]] && _found=1 && break
                        done
                        if (( ! _found )); then
                            log_error "Unknown symlink group: $1 (see --help for available groups)"
                            exit 1
                        fi
                    fi
                    SKIP_GROUPS+=("$_lower")
                    shift
                done
                continue
                ;;
            -o|--only)
                if [[ $# -lt 2 || "$2" == -* ]]; then
                    log_error "--only requires at least one group name"
                    exit 1
                fi
                shift
                while [[ $# -gt 0 && "$1" != -* ]]; do
                    local _lower
                    _lower="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
                    if [[ ${#valid_groups[@]} -gt 0 ]]; then
                        local _found=0
                        for _g in "${valid_groups[@]}"; do
                            [[ "$_g" == "$_lower" ]] && _found=1 && break
                        done
                        if (( ! _found )); then
                            log_error "Unknown symlink group: $1 (see --help for available groups)"
                            exit 1
                        fi
                    fi
                    ONLY_GROUPS+=("$_lower")
                    shift
                done
                continue
                ;;
            -n|--dry-run)        DRY_RUN=1 ;;
            -f|--force)          FORCE=1 ;;
            -h|--help)        show_help; exit 0 ;;
            core|cli|dev|extra|macos)
                CATEGORIES+=("$1")
                ;;
            *)
                log_error "Unknown option: $1"
                printf "\n"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

create_symlink() {
    local source="$1" target="$2"

    target="${target/#\~/$HOME}"

    [[ "$source" != /* ]] && source="${DOTFILES_DIR}/${source}"

    if [[ ! -e "$source" ]]; then
        # local/ sources come from the private repo: absent without it, and not yet
        # linked in a dry run (link.sh --dry-run creates nothing). Matched on the
        # repo-relative path so a checkout under e.g. /usr/local is not mistaken for one.
        if [[ "/${source#"$DOTFILES_DIR"/}" == */local/* ]]; then
            if [[ ! -d "$DOTFILES_PRIVATE" ]]; then
                log_skip "Needs private repo: ${source/#$DOTFILES_DIR/}"
                SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
                return 0
            fi
            if (( DRY_RUN )); then
                log_skip "Not checked, link.sh supplies it: ${source/#$DOTFILES_DIR/}"
                SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
                return 0
            fi
        fi
        log_warn "Source not found: ${source/#$HOME/$HOME_ABBREV}"
        SYMLINKS_FAILED=$((SYMLINKS_FAILED + 1))
        return 0
    fi

    local target_dir="${target%/*}"
    if [[ ! -d "$target_dir" ]]; then
        if (( DRY_RUN )); then
            log_info "[dry-run] Would create directory: ${target_dir/#$HOME/$HOME_ABBREV}"
        else
            mkdir -p "$target_dir"
        fi
    fi

    if [[ -L "$target" ]]; then
        local current
        current="$(readlink "$target")"
        if [[ "$current" == "$source" ]]; then
            log_skip "Already linked: ${target/#$HOME/$HOME_ABBREV}"
            SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
            return 0
        fi
        if (( ! FORCE )); then
            log_warn "Exists (different target): ${target/#$HOME/$HOME_ABBREV} -> $current"
            SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
            return 0
        fi
        (( ! DRY_RUN )) && rm -f "$target"
    elif [[ -e "$target" ]]; then
        if (( ! FORCE )); then
            log_warn "Exists (not a symlink): ${target/#$HOME/$HOME_ABBREV}"
            SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
            return 0
        fi
        if [[ -d "$target" ]]; then
            log_warn "Exists as directory: ${target/#$HOME/$HOME_ABBREV} (remove manually to replace with symlink)"
            SYMLINKS_FAILED=$((SYMLINKS_FAILED + 1))
            return 0
        fi
        (( ! DRY_RUN )) && rm -f "$target"
    fi

    if (( DRY_RUN )); then
        log_info "[dry-run] Would link: ${target/#$HOME/$HOME_ABBREV} -> ${source/#$DOTFILES_DIR/}"
    else
        ln -s "$source" "$target"
        log_success "${target/#$HOME/$HOME_ABBREV} -> ${source/#$DOTFILES_DIR/}"
    fi
    SYMLINKS_CREATED=$((SYMLINKS_CREATED + 1))
}

is_group_excluded() {
    local group="$1"
    [[ -z "$group" ]] && return 1
    local g
    if [[ ${#ONLY_GROUPS[@]} -gt 0 ]]; then
        for g in "${ONLY_GROUPS[@]}"; do
            [[ "$g" == "$group" ]] && return 1
        done
        return 0
    fi
    if [[ ${#SKIP_GROUPS[@]} -gt 0 ]]; then
        for g in "${SKIP_GROUPS[@]}"; do
            [[ "$g" == "$group" ]] && return 0
        done
    fi
    return 1
}

process_symlinks() {
    local platform="$1"

    log_header "Creating symlinks"

    if [[ ! -f "$SYMLINKS_CONF" ]]; then
        log_error "Missing: $SYMLINKS_CONF"
        return 1
    fi

    if [[ ${#ONLY_GROUPS[@]} -gt 0 ]]; then
        log_info "Only groups: ${ONLY_GROUPS[*]}"
    elif [[ ${#SKIP_GROUPS[@]} -gt 0 ]]; then
        log_info "Skipping groups: ${SKIP_GROUPS[*]}"
    fi

    local current_group=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^#[[:space:]]*@group[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
            current_group="$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')"
            continue
        fi

        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        local source target filter
        read -r source target filter <<< "$line"

        if [[ -n "${filter:-}" && "$filter" != "$platform" ]]; then
            continue
        fi

        if is_group_excluded "$current_group"; then
            SYMLINKS_EXCLUDED=$((SYMLINKS_EXCLUDED + 1))
            continue
        fi

        create_symlink "$source" "$target"
    done < "$SYMLINKS_CONF"
}

remove_symlinks() {
    local platform="$1"
    local count=0

    log_header "Removing managed symlinks"

    if [[ ! -f "$SYMLINKS_CONF" ]]; then
        log_error "Missing: $SYMLINKS_CONF"
        return 1
    fi

    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        local source target filter
        read -r source target filter <<< "$line"

        [[ -n "${filter:-}" && "$filter" != "$platform" ]] && continue

        target="${target/#\~/$HOME}"
        [[ "$source" != /* ]] && source="${DOTFILES_DIR}/${source}"

        if [[ -L "$target" ]]; then
            local current
            current="$(readlink "$target")"
            if [[ "$current" == "$source" ]]; then
                if (( DRY_RUN )); then
                    log_info "[dry-run] Would remove: ${target/#$HOME/$HOME_ABBREV}"
                else
                    rm -f "$target"
                    log_success "Removed: ${target/#$HOME/$HOME_ABBREV}"
                fi
                count=$((count + 1))
            fi
        fi
    done < "$SYMLINKS_CONF"

    if (( DRY_RUN )); then
        log_info "Would remove $count symlink(s)"
    else
        log_info "Removed $count symlink(s)"
    fi
}

link_private_repo() {
    if [[ ! -d "$DOTFILES_PRIVATE" ]]; then
        log_warn "Private dotfiles not found at ${DOTFILES_PRIVATE/#$HOME/$HOME_ABBREV} (skipping)"
        return 0
    fi

    local link_script="${DOTFILES_PRIVATE}/link.sh"
    if [[ ! -f "$link_script" ]]; then
        log_warn "Private link.sh not found (skipping)"
        return 0
    fi

    log_header "Linking private dotfiles"

    local -a cmd=(bash "$link_script")
    (( DRY_RUN )) && cmd+=(--dry-run)
    (( FORCE )) && cmd+=(--force)

    if ! "${cmd[@]}"; then
        log_error "Private dotfiles linking failed"
        log_error "Fix the issue and re-run: ${link_script/#$HOME/$HOME_ABBREV}"
        return 1
    fi
}

run_private_post_install() {
    local script="${DOTFILES_PRIVATE}/post-install.sh"
    [[ -f "$script" ]] || return 0

    log_header "Running private post-install"

    local -a cmd=(bash "$script" "$@")
    (( DRY_RUN )) && cmd+=(--dry-run)

    if ! "${cmd[@]}"; then
        log_error "Private post-install failed"
        log_error "Fix the issue and re-run: ${script/#$HOME/$HOME_ABBREV}"
        return 1
    fi
}

select_categories_interactive() {
    local platform="$1"

    log_header "Select package categories to install"

    local -a all_categories=("core" "cli" "dev" "extra")
    [[ "$platform" == "macos" ]] && all_categories+=("macos")

    local desc
    for cat in "${all_categories[@]}"; do
        case "$cat" in
            core)  desc="Shell, git, tmux, plugin manager, history, navigation" ;;
            cli)   desc="Modern CLI replacements, JSON/YAML tools, viewers, monitors" ;;
            dev)   desc="Editor, runtimes, git and lint tooling" ;;
            extra) desc="Benchmarks, code stats, document conversion, media, OCR, network and disk tools" ;;
            macos) desc="Hammerspoon, Karabiner-Elements, espanso, CLI tools" ;;
        esac
        printf "  ${BOLD}%-8s${NC} %s\n" "$cat" "$desc"
        printf "           Install? [y/N] "
        local answer
        read -r answer
        if [[ "$answer" =~ ^[Yy] ]]; then
            CATEGORIES+=("$cat")
        fi
    done
    printf "\n"

    if [[ ${#CATEGORIES[@]} -eq 0 ]]; then
        log_info "No categories selected, skipping package installation"
    else
        log_info "Selected: ${CATEGORIES[*]}"
    fi
}

install_apt_packages() {
    command -v apt-get &>/dev/null || return 0

    local -a apt_files=("${PACKAGES_DIR}/apt.txt") packages=()
    local category apt_file line
    for category in "${CATEGORIES[@]}"; do
        apt_files+=("${PACKAGES_DIR}/apt.${category}.txt")
    done
    for apt_file in "${apt_files[@]}"; do
        [[ -f "$apt_file" ]] || continue
        while IFS= read -r line; do
            packages+=("$line")
        done < <(apt_list_entries "$apt_file")
    done

    [[ ${#packages[@]} -eq 0 ]] && return 0

    if (( DRY_RUN )); then
        log_info "[dry-run] Would install apt packages: ${packages[*]}"
        return 0
    fi

    log_info "Installing system packages (apt)..."
    sudo apt-get update -qq || {
        log_warn "apt-get update failed (continuing)"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
    }
    sudo apt-get install -y -qq "${packages[@]}" || {
        log_warn "Some apt packages failed to install (continuing)"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
    }
}

install_brew_packages() {
    local platform="$1" category="$2"
    local brewfile="${PACKAGES_DIR}/Brewfile.${category}"

    if [[ ! -f "$brewfile" ]]; then
        log_warn "No Brewfile for category: $category"
        return 0
    fi

    if ! command -v brew &>/dev/null; then
        log_warn "Homebrew not installed, skipping: $category"
        log_warn "Install Homebrew: https://brew.sh"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
        return 0
    fi

    if (( DRY_RUN )); then
        log_info "[dry-run] Would install from Brewfile.$category:"
        brewfile_entries "$platform" "$brewfile" | sed -n 's/^brew "\(.*\)"/  - \1/p; s/^cask "\(.*\)"/  - \1 (cask)/p'
        return 0
    fi

    log_info "Installing $category packages (brew)..."
    brew bundle --file="$brewfile" --no-upgrade || {
        log_warn "Some $category packages may have failed (continuing)"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
    }
}

# Returns 0 when it installed NAME in this run (or would in a dry run). Callers
# test the status, so errexit does not apply inside: every failure is explicit.
install_github_deb() {
    local name="$1" repo="$2" deb_pattern="$3"

    if command -v "$name" &>/dev/null && (( ! FORCE )); then
        log_skip "Already installed: $name"
        return 1
    fi

    if ! command -v apt-get &>/dev/null; then
        log_warn "apt-get not found, skipping $name (Debian/Ubuntu required)"
        return 1
    fi

    local url
    url="https://github.com/${repo}/releases/latest/download/${deb_pattern}"

    if (( DRY_RUN )); then
        log_info "[dry-run] Would install $name from $url"
        return 0
    fi

    local tmp
    if ! tmp="$(mktemp --suffix=.deb)"; then
        log_warn "Could not create a temp file for $name"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
        return 1
    fi

    log_info "Downloading $name from GitHub releases..."
    if ! curl -fsSL -o "$tmp" "$url"; then
        log_warn "Failed to download $name"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
        rm -f "$tmp"
        return 1
    fi

    local rc=1
    log_info "Installing $name..."
    if sudo apt-get install -y -qq "$tmp"; then
        log_success "$name"
        rc=0
    else
        log_warn "Failed to install $name"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
    fi
    rm -f "$tmp"
    return "$rc"
}

install_local_packages() {
    local platform="$1" local_dir="${PACKAGES_DIR}/local"
    [[ -d "$local_dir" ]] || return 0
    command -v brew &>/dev/null || return 0

    local brewfile
    for brewfile in "$local_dir"/Brewfile*; do
        [[ -f "$brewfile" ]] || continue

        local name="${brewfile##*/}"

        if (( DRY_RUN )); then
            log_info "[dry-run] Would install from local/$name:"
            brewfile_entries "$platform" "$brewfile" \
                | sed -n 's/^brew "\(.*\)"/  - \1/p; s/^cask "\(.*\)"/  - \1 (cask)/p; s/^mas "\(.*\)".*/  - \1 (App Store)/p'
            continue
        fi

        log_info "Installing local packages ($name)..."
        brew bundle --file="$brewfile" --no-upgrade || {
            log_warn "Some local packages may have failed (continuing)"
            PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
        }
    done
}

install_linux_extras() {
    local platform="$1"

    # espanso runs on the Windows side under WSL
    [[ "$platform" != "linux" ]] && return 0

    local arch
    if command -v dpkg &>/dev/null; then
        arch="$(dpkg --print-architecture 2>/dev/null)" || arch="unknown"
        if [[ "$arch" != "$ESPANSO_DEB_ARCH" ]]; then
            log_skip "espanso: no .deb for $arch (upstream publishes $ESPANSO_DEB_ARCH only)"
            return 0
        fi
    fi

    local espanso_deb="espanso-debian-x11-${ESPANSO_DEB_ARCH}.deb" wayland=0
    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        espanso_deb="espanso-debian-wayland-${ESPANSO_DEB_ARCH}.deb"
        wayland=1
    fi

    local installed=0 espanso_bin caps
    install_github_deb "espanso" "espanso/espanso" "$espanso_deb" && installed=1
    (( wayland )) || return 0
    if (( ! installed )); then
        espanso_bin="$(command -v espanso)" || return 0
        # getcap shows the flags as =p or +p depending on the libcap version
        caps="$(getcap "$espanso_bin" 2>/dev/null)" || caps=""
        [[ "$caps" == *"${ESPANSO_WAYLAND_CAP%+*}"* ]] && return 0
    fi

    if (( DRY_RUN )); then
        log_info "[dry-run] Would grant espanso the capability $ESPANSO_WAYLAND_CAP"
        return 0
    fi
    if ! sudo setcap "$ESPANSO_WAYLAND_CAP" "$(command -v espanso)"; then
        log_warn "Could not grant espanso $ESPANSO_WAYLAND_CAP (run: sudo setcap \"$ESPANSO_WAYLAND_CAP\" \"\$(command -v espanso)\")"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
    fi
}

install_packages() {
    local platform="$1"

    if ! command -v brew &>/dev/null; then
        log_warn "Homebrew not found. Most packages require it: https://brew.sh"
    fi

    if [[ ${#CATEGORIES[@]} -eq 0 ]] && (( ! INSTALL_ALL )); then
        select_categories_interactive "$platform"
    fi

    if (( INSTALL_ALL )); then
        CATEGORIES=("core" "cli" "dev" "extra")
        [[ "$platform" == "macos" ]] && CATEGORIES+=("macos")
    fi

    [[ ${#CATEGORIES[@]} -eq 0 ]] && return 0

    log_header "Installing packages"

    if [[ "$platform" == "linux" || "$platform" == "wsl" ]]; then
        install_apt_packages
    fi

    for category in "${CATEGORIES[@]}"; do
        install_brew_packages "$platform" "$category"
    done

    install_local_packages "$platform"

    install_linux_extras "$platform"
}

# macOS espanso config path contains spaces (~/Library/Application Support/espanso/)
# which symlinks.conf cannot handle, so this is done separately.

espanso_target_dir() {
    case "$(detect_platform)" in
        macos) printf '%s' "${HOME}/Library/Application Support/espanso" ;;
        linux) printf '%s' "${HOME}/.config/espanso" ;;
        # WSL: espanso runs on the Windows side
        *)     return 1 ;;
    esac
}

link_espanso_config() {
    if is_group_excluded "espanso"; then
        SYMLINKS_EXCLUDED=$((SYMLINKS_EXCLUDED + 1))
        return 0
    fi

    local espanso_source="${DOTFILES_DIR}/espanso/local"
    local espanso_target
    espanso_target="$(espanso_target_dir)" || return 0

    if [[ ! -d "$espanso_source/config" || ! -d "$espanso_source/match" ]]; then
        log_skip "Espanso config not found (populate espanso/local/ first)"
        return 0
    fi

    local dir
    for dir in config match; do
        create_symlink "${espanso_source}/${dir}" "${espanso_target}/${dir}"
    done
}

unlink_espanso_config() {
    local espanso_source="${DOTFILES_DIR}/espanso/local"
    local espanso_target
    espanso_target="$(espanso_target_dir)" || return 0

    local dir
    for dir in config match; do
        local src="${espanso_source}/${dir}"
        local tgt="${espanso_target}/${dir}"

        if [[ -L "$tgt" ]]; then
            local current
            current="$(readlink "$tgt")"
            if [[ "$current" == "$src" ]]; then
                if (( DRY_RUN )); then
                    log_info "[dry-run] Would remove: ${tgt/#$HOME/$HOME_ABBREV}"
                else
                    rm -f "$tgt"
                    log_success "Removed: ${tgt/#$HOME/$HOME_ABBREV}"
                fi
            fi
        fi
    done
}

reconcile_skill_deps() {
    local dir="$1" refs="${1}/references"
    [[ -f "${refs}/pyproject.toml" ]] || return 0
    if [[ ! -d "${refs}/.venv" ]]; then
        log_skip "${dir##*/}: code updated but no render venv (uv sync manually in ${refs/#$HOME/$HOME_ABBREV})"
        return 0
    fi
    command -v uv &>/dev/null || return 0
    if ( cd "$refs" && uv sync --quiet 2>/dev/null ); then
        log_success "${dir##*/}: render dependencies synced"
    else
        log_warn "${dir##*/}: uv sync failed (run manually in ${refs/#$HOME/$HOME_ABBREV})"
    fi
}

update_claude_skills() {
    log_header "Update Claude skills"

    local skills_dir="${HOME}/.claude/skills"
    if [[ ! -d "$skills_dir" ]]; then
        log_skip "No skills directory at ${skills_dir/#$HOME/$HOME_ABBREV}"
        return 0
    fi
    if ! command -v git &>/dev/null; then
        log_error "git not available, cannot update skills"
        return 1
    fi

    local updated=0 current=0 skipped=0 failed=0 found=0
    local dir name branch before after pull_err

    for dir in "$skills_dir"/*/; do
        dir="${dir%/}"
        [[ -d "${dir}/.git" ]] || continue
        found=$((found + 1))
        name="${dir##*/}"

        if ! branch="$(git -C "$dir" symbolic-ref --quiet --short HEAD 2>/dev/null)"; then
            log_skip "${name}: detached HEAD, skipping"
            skipped=$((skipped + 1)); continue
        fi
        if ! git -C "$dir" rev-parse --quiet --verify '@{upstream}' >/dev/null 2>&1; then
            log_skip "${name}: no upstream for '${branch}', skipping"
            skipped=$((skipped + 1)); continue
        fi
        if [[ -n "$(git -C "$dir" status --porcelain --untracked-files=no)" ]]; then
            log_warn "${name}: uncommitted local changes, skipping"
            skipped=$((skipped + 1)); continue
        fi

        if (( DRY_RUN )); then
            log_info "[dry-run] Would update ${name} (git pull --ff-only)"
            continue
        fi

        before="$(git -C "$dir" rev-parse --short HEAD)"
        if ! pull_err="$(GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new" \
            git -C "$dir" pull --ff-only --quiet 2>&1)"; then
            log_warn "${name}: pull failed: ${pull_err##*$'\n'} (manual: git -C ${dir/#$HOME/$HOME_ABBREV} pull --ff-only)"
            failed=$((failed + 1)); continue
        fi
        after="$(git -C "$dir" rev-parse --short HEAD)"

        if [[ "$before" == "$after" ]]; then
            log_skip "${name}: already up to date"
            current=$((current + 1))
        else
            log_success "${name}: ${before} -> ${after}"
            updated=$((updated + 1))
            reconcile_skill_deps "$dir"
        fi
    done

    if (( found == 0 )); then
        log_skip "No git-backed skills in ${skills_dir/#$HOME/$HOME_ABBREV}"
        return 0
    fi
    log_info "Skills: ${updated} updated, ${current} current, ${skipped} skipped, ${failed} failed"
    return $(( failed > 0 ))
}

setup_excalidraw_render_pipeline() {
    local refs="${HOME}/.claude/skills/excalidraw-diagram/references"
    [[ -f "${refs}/pyproject.toml" ]] || return 0

    if ! command -v uv &>/dev/null; then
        log_skip "Excalidraw render pipeline: uv not available"
        return 0
    fi
    if (( DRY_RUN )); then
        log_info "[dry-run] Would set up Excalidraw render pipeline (uv sync + playwright chromium)"
        return 0
    fi

    log_info "Setting up Excalidraw render pipeline..."
    if ! ( cd "$refs" && uv sync --quiet 2>/dev/null ); then
        log_warn "Excalidraw render pipeline: uv sync failed (run manually in ${refs/#$HOME/$HOME_ABBREV})"
        return 0
    fi
    if ( cd "$refs" && uv run --quiet playwright install chromium >/dev/null 2>&1 ); then
        log_success "Excalidraw render pipeline ready"
    else
        log_warn "Excalidraw render pipeline: chromium install failed (Linux may need: cd ${refs/#$HOME/$HOME_ABBREV} && uv run playwright install-deps)"
    fi
}

post_install() {
    log_header "Post-install"

    if command -v sheldon &>/dev/null; then
        if [[ -f "${HOME}/.config/sheldon/plugins.toml" ]]; then
            if (( DRY_RUN )); then
                log_info "[dry-run] Would run: sheldon lock --update"
            else
                log_info "Updating sheldon plugins..."
                if sheldon lock --update 2>/dev/null; then
                    log_success "Sheldon plugins locked"
                else
                    log_warn "sheldon lock failed (run manually: sheldon lock --update)"
                fi
            fi
        fi
    else
        log_skip "Sheldon not installed"
    fi

    local tpm_dir="${HOME}/.tmux/plugins/tpm"
    if [[ ! -d "$tpm_dir" ]]; then
        if command -v git &>/dev/null; then
            if (( DRY_RUN )); then
                log_info "[dry-run] Would install TPM"
            else
                log_info "Installing TPM..."
                if git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null; then
                    log_success "TPM installed (press prefix+I in tmux to install plugins)"
                else
                    log_warn "TPM install failed"
                fi
            fi
        fi
    else
        log_skip "TPM already installed"
    fi

    # Cloned from our fork (DreamTimeZ/excalidraw-diagram-skill), which carries a UMD-bundle
    # render patch working around intermittent esm.sh 404s. Rebase the fork on upstream to pull updates.
    local excalidraw_skill="${HOME}/.claude/skills/excalidraw-diagram"
    if [[ ! -d "${excalidraw_skill}/.git" ]]; then
        if command -v git &>/dev/null; then
            if (( DRY_RUN )); then
                log_info "[dry-run] Would install Excalidraw diagram skill"
            else
                log_info "Installing Excalidraw diagram skill..."
                if git clone --depth 1 https://github.com/DreamTimeZ/excalidraw-diagram-skill "$excalidraw_skill" 2>/dev/null; then
                    log_success "Excalidraw diagram skill installed"
                else
                    log_warn "Excalidraw diagram skill install failed"
                fi
            fi
        else
            log_skip "git not available, skipping Excalidraw diagram skill"
        fi
    else
        log_skip "Excalidraw diagram skill already installed (refresh with: ./setup.sh --update)"
    fi

    if command -v mise &>/dev/null; then
        if [[ -f "${HOME}/.config/mise/config.toml" ]]; then
            if (( DRY_RUN )); then
                log_info "[dry-run] Would run: mise install"
            else
                log_info "Installing mise-managed tools..."
                if mise install --yes 2>/dev/null; then
                    log_success "Mise tools installed"
                else
                    log_warn "mise install failed (run manually: mise install)"
                fi
            fi
        fi
    else
        log_skip "Mise not installed"
    fi

    # Needs uv, installed by packages/mise above
    setup_excalidraw_render_pipeline

    if command -v nvim &>/dev/null; then
        if [[ -f "${HOME}/.config/nvim/init.lua" ]]; then
            if (( DRY_RUN )); then
                log_info "[dry-run] Would sync neovim plugins"
            else
                log_info "Syncing neovim plugins..."
                if nvim --headless "+Lazy! sync" +qa 2>/dev/null; then
                    log_success "Neovim plugins synced"
                else
                    log_warn "Neovim plugin sync failed (open nvim to install manually)"
                fi
            fi
        fi
    else
        log_skip "Neovim not installed"
    fi

    fix_permissions
}

fix_permissions() {
    if (( DRY_RUN )); then
        log_info "[dry-run] Would fix SSH/GPG permissions"
        return 0
    fi

    local fixed=0

    if [[ -d "${HOME}/.ssh" ]]; then
        chmod 700 "${HOME}/.ssh" 2>/dev/null || true
        find "${HOME}/.ssh" -maxdepth 1 -name "config*" -exec chmod 600 {} \; 2>/dev/null || true
        fixed=$((fixed + 1))
    fi

    if [[ -d "${HOME}/.gnupg" ]]; then
        chmod 700 "${HOME}/.gnupg" 2>/dev/null || true
        find "${HOME}/.gnupg" -maxdepth 1 -name "*.conf" -exec chmod 600 {} \; 2>/dev/null || true
        fixed=$((fixed + 1))
    fi

    (( fixed > 0 )) && log_success "File permissions fixed" || true
}

check_dir_permissions() {
    local dir="$1" expected="$2" label="$3"
    if [[ -d "$dir" ]]; then
        local perms
        perms="$(stat -c '%a' "$dir" 2>/dev/null)" || \
        perms="$(stat -f '%Lp' "$dir" 2>/dev/null)" || \
        perms="unknown"

        if [[ "$perms" == "$expected" ]]; then
            log_success "$label ($perms)"
        else
            log_warn "$label has permissions $perms (expected $expected)"
            return 1
        fi
    fi
    return 0
}

run_doctor() {
    local platform="$1"
    local issues=0

    log_header "Dotfiles health check"

    printf '%bSymlinks%b\n' "$BOLD" "$NC"
    if [[ -f "$SYMLINKS_CONF" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

            local source target filter
            read -r source target filter <<< "$line"

            [[ -n "${filter:-}" && "$filter" != "$platform" ]] && continue

            target="${target/#\~/$HOME}"
            [[ "$source" != /* ]] && source="${DOTFILES_DIR}/${source}"

            if [[ ! -e "$source" && ! -L "$source" ]]; then
                log_skip "Source missing: ${source/#$DOTFILES_DIR/} (expected, needs private repo or manual setup)"
                continue
            fi

            if [[ -L "$target" ]]; then
                local current
                current="$(readlink "$target")"
                if [[ "$current" == "$source" ]]; then
                    log_success "${target/#$HOME/$HOME_ABBREV}"
                else
                    log_warn "${target/#$HOME/$HOME_ABBREV} -> wrong target"
                    issues=$((issues + 1))
                fi
            elif [[ -e "$target" ]]; then
                log_warn "${target/#$HOME/$HOME_ABBREV} exists but is not a symlink"
                issues=$((issues + 1))
            else
                log_error "${target/#$HOME/$HOME_ABBREV} missing"
                issues=$((issues + 1))
            fi
        done < "$SYMLINKS_CONF"
    else
        log_error "symlinks.conf not found"
        issues=$((issues + 1))
    fi

    local espanso_target
    if espanso_target="$(espanso_target_dir)"; then
        local espanso_source="${DOTFILES_DIR}/espanso/local"
        if [[ -d "$espanso_source/config" && -d "$espanso_source/match" ]]; then
            local _dir
            for _dir in config match; do
                local _src="${espanso_source}/${_dir}"
                local _tgt="${espanso_target}/${_dir}"
                if [[ -L "$_tgt" ]]; then
                    local _current
                    _current="$(readlink "$_tgt")"
                    if [[ "$_current" == "$_src" ]]; then
                        log_success "${_tgt/#$HOME/$HOME_ABBREV}"
                    else
                        log_warn "${_tgt/#$HOME/$HOME_ABBREV} -> wrong target"
                        issues=$((issues + 1))
                    fi
                elif [[ -d "$_tgt" ]]; then
                    log_warn "${_tgt/#$HOME/$HOME_ABBREV} exists but is not a symlink (remove it manually, then run setup.sh --link-only)"
                    issues=$((issues + 1))
                else
                    log_error "${_tgt/#$HOME/$HOME_ABBREV} missing"
                    issues=$((issues + 1))
                fi
            done
        else
            log_skip "Espanso config not found (populate espanso/local/ first)"
        fi
    fi

    printf '\n%bRequired tools%b\n' "$BOLD" "$NC"
    local -a required_tools=(git zsh tmux sheldon fzf)
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_success "$tool"
        else
            log_error "$tool not found"
            issues=$((issues + 1))
        fi
    done

    printf '\n%bRecommended tools%b\n' "$BOLD" "$NC"
    local -a recommended_tools=(bat eza fd rg jq zoxide atuin glow nvim mise lazygit gh uv ffmpeg tesseract)
    local private_tools_file="${DOTFILES_PRIVATE}/shared/doctor-tools.txt"
    if [[ -f "$private_tools_file" ]]; then
        while IFS= read -r _line; do
            [[ -z "$_line" || "$_line" =~ ^[[:space:]]*# ]] && continue
            recommended_tools+=("$_line")
        done < "$private_tools_file"
    fi
    for tool in "${recommended_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_success "$tool"
        else
            log_warn "$tool not installed"
        fi
    done

    printf '\n%bPrivate dotfiles%b\n' "$BOLD" "$NC"
    if [[ -d "$DOTFILES_PRIVATE" ]]; then
        log_success "Private repo found"
        if [[ -f "${DOTFILES_PRIVATE}/link.sh" ]]; then
            log_success "link.sh present"
        else
            log_warn "link.sh missing"
            issues=$((issues + 1))
        fi
    else
        log_skip "Private repo not found (optional)"
    fi

    printf '\n%bPermissions%b\n' "$BOLD" "$NC"
    # shellcheck disable=SC2088
    check_dir_permissions "${HOME}/.ssh" "700" "~/.ssh" || issues=$((issues + 1))
    # shellcheck disable=SC2088
    check_dir_permissions "${HOME}/.gnupg" "700" "~/.gnupg" || issues=$((issues + 1))

    printf '\n%bPlugin managers%b\n' "$BOLD" "$NC"
    if [[ -f "${HOME}/.local/share/sheldon/plugins.lock" ]]; then
        log_success "Sheldon lockfile"
    else
        log_warn "Sheldon lockfile missing (run: sheldon lock)"
        issues=$((issues + 1))
    fi

    if [[ -d "${HOME}/.tmux/plugins/tpm" ]]; then
        log_success "TPM installed"
    else
        log_warn "TPM not installed (setup.sh will install it)"
        issues=$((issues + 1))
    fi

    if command -v mise &>/dev/null; then
        printf '\n%bMise tools%b\n' "$BOLD" "$NC"
        if [[ -f "${HOME}/.config/mise/config.toml" ]]; then
            log_success "Global config"
        else
            log_warn "Global config missing (~/.config/mise/config.toml)"
            issues=$((issues + 1))
        fi
        local missing_tools
        if ! missing_tools="$(mise ls --missing 2>/dev/null)"; then
            log_warn "mise ls --missing failed (run it to see why)"
            issues=$((issues + 1))
        elif [[ -n "$missing_tools" ]]; then
            log_warn "Missing tools (run: mise install)"
            issues=$((issues + 1))
        else
            log_success "All tools installed"
        fi
    fi

    printf "\n"
    if (( issues == 0 )); then
        log_info "All checks passed"
    else
        log_warn "$issues issue(s) found"
    fi

    return $(( issues > 0 ? 1 : 0 ))
}

main() {
    parse_args "$@"

    if (( LINK_ONLY && PACKAGES_ONLY )); then
        log_error "--link-only and --packages-only are mutually exclusive"
        exit 1
    fi

    if [[ ${#SKIP_GROUPS[@]} -gt 0 && ${#ONLY_GROUPS[@]} -gt 0 ]]; then
        log_error "--skip and --only are mutually exclusive"
        exit 1
    fi

    if (( DO_UNLINK )) && [[ ${#SKIP_GROUPS[@]} -gt 0 || ${#ONLY_GROUPS[@]} -gt 0 ]]; then
        log_error "--unlink does not support --skip or --only"
        exit 1
    fi

    local platform
    platform="$(detect_platform)"

    printf "\n"
    (( DRY_RUN )) && log_info "Dry run mode (no changes will be made)"
    log_info "Platform: $platform"
    log_info "Dotfiles: ${DOTFILES_DIR/#$HOME/$HOME_ABBREV}"
    printf "\n"

    if (( DO_DOCTOR )); then
        run_doctor "$platform"
        exit $?
    fi

    if (( DO_UNLINK )); then
        remove_symlinks "$platform"
        unlink_espanso_config
        exit 0
    fi

    # Under set -e a failed half would skip the other
    if (( DO_UPDATE )); then
        local rc=0
        update_claude_skills || rc=1
        run_private_post_install --update-skills || rc=1
        exit "$rc"
    fi

    local private_post_install_failed=0

    # Link private repo first (populates local/ dirs for packages and configs)
    if (( ! PACKAGES_ONLY )); then
        link_private_repo
    fi

    if (( ! LINK_ONLY )); then
        install_packages "$platform"
    fi

    if (( ! PACKAGES_ONLY )); then
        process_symlinks "$platform"
        link_espanso_config
        if (( ! LINK_ONLY )); then
            post_install
            run_private_post_install || private_post_install_failed=1
        fi
    fi

    log_header "Done"
    local summary
    if (( DRY_RUN )); then
        summary="Symlinks: $SYMLINKS_CREATED would create, $SYMLINKS_SKIPPED unchanged, $SYMLINKS_FAILED would fail"
    else
        summary="Symlinks: $SYMLINKS_CREATED created, $SYMLINKS_SKIPPED unchanged, $SYMLINKS_FAILED failed"
    fi
    (( SYMLINKS_EXCLUDED > 0 )) && summary+=", $SYMLINKS_EXCLUDED excluded"
    log_info "$summary"
    (( PACKAGES_WARNED > 0 )) && log_warn "Package warnings: $PACKAGES_WARNED (review output above)"
    (( private_post_install_failed )) && log_warn "Private post-install failed (review output above)"

    if [[ ! -d "$DOTFILES_PRIVATE" ]]; then
        printf "\n"
        log_info "Tip: Clone your private dotfiles to ${DOTFILES_PRIVATE/#$HOME/$HOME_ABBREV}"
        log_info "     Then re-run: ./setup.sh --all"
    fi

    if (( SYMLINKS_FAILED > 0 || PACKAGES_WARNED > 0 || private_post_install_failed )); then
        exit 1
    fi
}

main "$@"
