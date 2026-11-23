#!/usr/bin/env bash
# Fresh-machine bootstrap for macOS, Linux (Ubuntu, Debian) and WSL. Run it as
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/DreamTimeZ/.dotfiles/main/bootstrap.sh)" -- [<private-repo-url>] [category ...]
# or with DOTFILES_PRIVATE_URL set. Never pipe it into bash: the selection and
# the key step prompt on stdin. Everything sits in main so a truncated download runs nothing.

main() {
    set -euo pipefail

    local -r RED='\033[0;31m'
    local -r GREEN='\033[0;32m'
    local -r YELLOW='\033[1;33m'
    local -r BLUE='\033[0;34m'
    local -r BOLD='\033[1m'
    local -r DIM='\033[2m'
    local -r NC='\033[0m'

    local -r PUBLIC_DIR="$HOME/.dotfiles"
    local -r PRIVATE_DIR="$HOME/.dotfiles-private"
    local -r PUBLIC_HTTPS_URL='https://github.com/DreamTimeZ/.dotfiles.git'
    local -r PUBLIC_SSH_URL='git@github.com:DreamTimeZ/.dotfiles.git'
    local -r PUBLIC_SNAPSHOT_URL='https://github.com/DreamTimeZ/.dotfiles/archive/refs/heads/main.tar.gz'
    local -r SNAPSHOT_ARCHIVE_NAME='snapshot.tar.gz'

    local -r BREW_INSTALL_URL='https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'
    local -r BREW_PREFIX_MACOS='/opt/homebrew'
    local -r BREW_PREFIX_LINUX='/home/linuxbrew/.linuxbrew'
    local -a APT_PACKAGES=(build-essential procps curl file git openssh-client)
    local -r APT_INSTALLED_STATUS='install ok installed'

    local -r SSH_DIR="$HOME/.ssh"
    local -r KEY_FILE="$SSH_DIR/github"
    local -r KNOWN_HOSTS="$SSH_DIR/known_hosts"
    local -r KEY_DATE_FORMAT='+%Y-%m-%d'
    local -r KEY_KDF_ROUNDS=100
    local -r MACOS_SSH_ADD='/usr/bin/ssh-add'
    local -r SSH_ADD_NO_AGENT_RC=2
    local -r GITHUB_HOST_KEY='github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'
    local -r GITHUB_HOST_KEY_FINGERPRINT='SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU'
    local -r GITHUB_KEY_PAGE='https://github.com/settings/ssh/new'
    # GitHub ends every ssh -T session with exit 1, also on success.
    local -r GITHUB_SSH_SUCCESS_RC=1
    local -r GITHUB_SSH_SUCCESS_TEXT='successfully authenticated'
    # shellcheck disable=SC2088 # git runs it through sh, which expands the tilde
    local -r CLONE_SSH_COMMAND='ssh -i ~/.ssh/github -o IdentitiesOnly=yes'

    local platform brew_prefix ssh_add uid arg
    local private_url="${DOTFILES_PRIVATE_URL:-}"
    local arg_url=''
    local -a select_words=()
    local github_ssh_output=''
    local github_ssh_ready=0
    local key_created=0

    log_info()    { printf '%b==>%b %b%s%b\n' "$BLUE" "$NC" "$BOLD" "$1" "$NC"; }
    log_success() { printf ' %bok%b %s\n' "$GREEN" "$NC" "$1"; }
    log_skip()    { printf ' %b-- %s%b\n' "$DIM" "$1" "$NC"; }
    log_warn()    { printf ' %b!!%b %s\n' "$YELLOW" "$NC" "$1"; }
    log_error()   { printf ' %b!!%b %s\n' "$RED" "$NC" "$1" >&2; }
    die()         { log_error "$1"; exit 1; }

    detect_platform() {
        case "$(uname -s)" in
            Darwin) echo macos ;;
            Linux) echo linux ;;
            *) die "Unsupported system: $(uname -s)" ;;
        esac
    }

    run_select() {
        "$1" --select ${select_words[@]+"${select_words[@]}"} \
            || die "Package selection cancelled or invalid, nothing installed"
    }

    # setup.sh saves the choice per machine, so the hand-over runs it plain.
    # Without ~/.dotfiles a snapshot's copy asks: a clone needs git, which a
    # fresh Mac only gets with Homebrew.
    select_packages() {
        local snapshot_dir archive
        log_info "Package selection"
        if [[ -x "$PUBLIC_DIR/setup.sh" ]]; then
            run_select "$PUBLIC_DIR/setup.sh"
            return
        fi
        [[ ! -e "$PUBLIC_DIR" ]] || die "$PUBLIC_DIR/setup.sh is missing or not executable"
        snapshot_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-snapshot.XXXXXX")"
        # Expanded now: bash 3.2 unwinds the locals before an EXIT trap runs.
        # shellcheck disable=SC2064
        trap "rm -rf $(printf '%q' "$snapshot_dir")" EXIT
        # Not piped into tar: a tar that quits early makes curl fail with EPIPE.
        archive="$snapshot_dir/$SNAPSHOT_ARCHIVE_NAME"
        if ! curl -fsSL -o "$archive" "$PUBLIC_SNAPSHOT_URL"; then
            die "Could not download the public repo snapshot from $PUBLIC_SNAPSHOT_URL"
        fi
        if ! tar -xzf "$archive" -C "$snapshot_dir" --strip-components 1; then
            die "Could not unpack the public repo snapshot from $PUBLIC_SNAPSHOT_URL"
        fi
        rm -f "$archive"
        [[ -x "$snapshot_dir/setup.sh" ]] || die "The public repo snapshot has no executable setup.sh"
        run_select "$snapshot_dir/setup.sh"
        # The hand-over ends in exec, which skips the EXIT trap.
        rm -rf "$snapshot_dir"
        trap - EXIT
    }

    install_apt_prerequisites() {
        local pkg status
        local -a missing=()
        log_info "System packages"
        for pkg in "${APT_PACKAGES[@]}"; do
            if status="$(dpkg-query -W -f="\${Status}" "$pkg" 2>/dev/null)" \
                && [[ "$status" == "$APT_INSTALLED_STATUS" ]]; then
                continue
            fi
            missing+=("$pkg")
        done
        if [[ ${#missing[@]} -eq 0 ]]; then
            log_skip "${APT_PACKAGES[*]} already installed"
            return
        fi
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
        log_success "Installed ${missing[*]}"
    }

    # PATH before the default prefix: the stub suite relies on its fake brew
    # winning on hosts that have a real Homebrew at the prefix.
    find_brew() {
        command -v brew && return
        [[ -x "$1/bin/brew" ]] && printf '%s\n' "$1/bin/brew"
    }

    setup_homebrew() {
        local brew_bin installer brew_env
        log_info "Homebrew"
        if brew_bin="$(find_brew "$brew_prefix")"; then
            log_skip "Already installed at $brew_bin"
        else
            # Downloaded first: inside the installer's usual one-liner a failed
            # curl is masked and bash runs an empty script successfully.
            if ! installer="$(curl -fsSL "$BREW_INSTALL_URL")"; then
                die "Could not download the Homebrew installer from $BREW_INSTALL_URL"
            fi
            if ! /bin/bash -c "$installer"; then
                die "The Homebrew installer failed"
            fi
            brew_bin="$(find_brew "$brew_prefix")" \
                || die "The Homebrew installer finished, but no brew is in $brew_prefix/bin or on PATH"
            log_success "Installed at $brew_bin"
        fi
        # This process only: later shells get Homebrew on PATH from the linked
        # ~/.zprofile, and setup.sh skips a real ~/.zprofile instead of linking it.
        brew_env="$("$brew_bin" shellenv)" || die "$brew_bin shellenv failed"
        eval "$brew_env"
    }

    ensure_github_key() {
        local host today
        if [[ -f "$KEY_FILE" ]]; then
            log_skip "SSH key $KEY_FILE exists"
        else
            if [[ ! -d "$SSH_DIR" ]]; then
                mkdir -m 700 "$SSH_DIR"
            fi
            host="$(hostname -s)"
            today="$(date "$KEY_DATE_FORMAT")"
            log_info "Creating $KEY_FILE, choose a passphrase"
            ssh-keygen -t ed25519 -a "$KEY_KDF_ROUNDS" -C "$host-$today" -f "$KEY_FILE"
            key_created=1
        fi
        [[ -f "$KEY_FILE.pub" ]] \
            || die "$KEY_FILE.pub is missing, recreate it with: ssh-keygen -y -f $KEY_FILE > $KEY_FILE.pub"
    }

    add_key_to_agent() {
        local key_line fingerprint listed rc
        key_line="$(ssh-keygen -lf "$KEY_FILE.pub")"
        read -r _ fingerprint _ <<<"$key_line"
        if listed="$("$ssh_add" -l 2>&1)"; then rc=0; else rc=$?; fi
        if [[ $rc -eq $SSH_ADD_NO_AGENT_RC ]]; then
            log_warn "No ssh-agent reachable, ssh asks for the key passphrase on every connection"
            return
        fi
        if [[ "$listed" == *"$fingerprint"* ]]; then
            log_skip "Key already in the ssh-agent"
            return
        fi
        if [[ "$platform" == macos ]]; then
            if "$ssh_add" --apple-use-keychain "$KEY_FILE"; then rc=0; else rc=$?; fi
        else
            if "$ssh_add" "$KEY_FILE"; then rc=0; else rc=$?; fi
        fi
        if [[ $rc -eq 0 ]]; then
            log_success "Key added to the ssh-agent"
        else
            log_warn "ssh-add failed, ssh asks for the key passphrase on every connection"
        fi
    }

    seed_known_hosts() {
        local tmp key_line actual
        if [[ -f "$KNOWN_HOSTS" ]] && ssh-keygen -F github.com -f "$KNOWN_HOSTS" >/dev/null; then
            log_skip "github.com already in $KNOWN_HOSTS"
            return
        fi
        tmp="$(mktemp "${TMPDIR:-/tmp}/github-host-key.XXXXXX")"
        printf '%s\n' "$GITHUB_HOST_KEY" >"$tmp"
        if ! key_line="$(ssh-keygen -lf "$tmp")"; then
            rm -f "$tmp"
            die "Could not fingerprint the GitHub host key, $KNOWN_HOSTS left unchanged"
        fi
        rm -f "$tmp"
        read -r _ actual _ <<<"$key_line"
        [[ "$actual" == "$GITHUB_HOST_KEY_FINGERPRINT" ]] \
            || die "GitHub host key fingerprint is $actual, expected $GITHUB_HOST_KEY_FINGERPRINT, $KNOWN_HOSTS left unchanged"
        if [[ -s "$KNOWN_HOSTS" && -n "$(tail -c 1 "$KNOWN_HOSTS")" ]]; then
            printf '\n' >>"$KNOWN_HOSTS"
        fi
        printf '%s\n' "$GITHUB_HOST_KEY" >>"$KNOWN_HOSTS"
        log_success "Added GitHub's host key to $KNOWN_HOSTS"
    }

    github_accepts_key() {
        local rc
        if github_ssh_output="$(ssh -i "$KEY_FILE" -o IdentitiesOnly=yes -T git@github.com </dev/null 2>&1)"; then
            rc=0
        else
            rc=$?
        fi
        [[ $rc -eq $GITHUB_SSH_SUCCESS_RC && "$github_ssh_output" == *"$GITHUB_SSH_SUCCESS_TEXT"* ]]
    }

    show_public_key() {
        log_info "Public key, add it on GitHub as an authentication key"
        cat "$KEY_FILE.pub"
        if [[ "$platform" == macos ]]; then
            if pbcopy <"$KEY_FILE.pub"; then
                log_success "Copied to the clipboard"
            else
                log_warn "Could not copy the key to the clipboard"
            fi
        fi
    }

    open_key_page() {
        log_info "Add it at $GITHUB_KEY_PAGE"
        if [[ "$platform" == macos ]]; then
            if ! open "$GITHUB_KEY_PAGE"; then
                log_warn "Could not open the browser, open the URL above yourself"
            fi
        elif command -v xdg-open >/dev/null; then
            if ! xdg-open "$GITHUB_KEY_PAGE" >/dev/null 2>&1; then
                log_warn "Could not open the browser, open the URL above yourself"
            fi
        fi
    }

    wait_for_github_access() {
        local answer
        if ! read -r -p "Press Enter once the key is saved on GitHub " answer; then
            return
        fi
        while true; do
            if github_accepts_key; then
                log_success "GitHub accepts $KEY_FILE"
                github_ssh_ready=1
                return
            fi
            log_warn "GitHub did not accept $KEY_FILE:"
            printf '%s\n' "$github_ssh_output"
            if ! read -r -p "Retry (r) or skip the private repo (s)? [R/s] " answer; then
                return
            fi
            case "$answer" in
                s | S) return ;;
            esac
        done
    }

    setup_github_ssh() {
        ensure_github_key
        add_key_to_agent
        seed_known_hosts
        # A key created moments ago cannot be registered yet, and without an
        # agent the check would ask for its passphrase only to fail.
        if [[ $key_created -eq 0 ]] && github_accepts_key; then
            log_skip "GitHub already accepts $KEY_FILE"
            github_ssh_ready=1
            return
        fi
        show_public_key
        open_key_page
        wait_for_github_access
    }

    # An earlier run without SSH access cloned over https. Only that exact
    # origin is switched, so a fork remote or a copied tree stays untouched.
    switch_public_origin_to_ssh() {
        local origin
        [[ -e "$PUBLIC_DIR/.git" ]] || return 0
        if ! origin="$(git -C "$PUBLIC_DIR" remote get-url origin 2>/dev/null)"; then
            return
        fi
        if [[ "$origin" == "$PUBLIC_HTTPS_URL" ]]; then
            git -C "$PUBLIC_DIR" remote set-url origin "$PUBLIC_SSH_URL"
            log_success "Switched the $PUBLIC_DIR origin to $PUBLIC_SSH_URL"
        fi
    }

    clone_repo() {
        local url=$1 dir=$2
        if [[ -d "$dir" ]]; then
            log_skip "$dir exists"
            return
        fi
        git clone "$url" "$dir"
        log_success "Cloned $dir"
    }

    clone_repo_ssh() {
        local url=$1 dir=$2
        if [[ -d "$dir" ]]; then
            log_skip "$dir exists"
            return
        fi
        GIT_SSH_COMMAND="$CLONE_SSH_COMMAND" git clone "$url" "$dir"
        log_success "Cloned $dir"
    }

    clone_repositories() {
        log_info "Repositories"
        if [[ $github_ssh_ready -eq 1 ]]; then
            switch_public_origin_to_ssh
            clone_repo_ssh "$PUBLIC_SSH_URL" "$PUBLIC_DIR"
            clone_repo_ssh "$private_url" "$PRIVATE_DIR"
        else
            clone_repo "$PUBLIC_HTTPS_URL" "$PUBLIC_DIR"
        fi
    }

    for arg in "$@"; do
        case "$arg" in
            # No category name is one letter long, so -x is one of setup.sh's options.
            --* | - | -?) die "Unknown option $arg: bootstrap takes the private repo URL and category words only, pass other options to $PUBLIC_DIR/setup.sh" ;;
            *:* | */*)
                [[ -z "$arg_url" ]] || die "Two private repo URLs given: $arg_url and $arg"
                arg_url=$arg
                ;;
            *) select_words+=("$arg") ;;
        esac
    done
    [[ -z "$arg_url" ]] || private_url=$arg_url

    uid="$(id -u)"
    [[ "$uid" -ne 0 ]] || die "Run bootstrap as your normal user, not as root"

    platform="$(detect_platform)"
    case "$platform" in
        macos)
            brew_prefix=$BREW_PREFIX_MACOS
            # Homebrew's openssh, first on PATH after shellenv, lacks --apple-use-keychain.
            ssh_add=$MACOS_SSH_ADD
            ;;
        *)
            # Before the selection, so an unsupported Linux stops before any question
            command -v apt-get >/dev/null || die "apt-get not found: bootstrap supports only Ubuntu and Debian on Linux"
            brew_prefix=$BREW_PREFIX_LINUX
            ssh_add=ssh-add
            ;;
    esac

    select_packages

    if [[ "$platform" != macos ]]; then
        install_apt_prerequisites
    fi

    # Before Homebrew, so every question comes in the first minutes.
    log_info "GitHub SSH access"
    if [[ -d "$PRIVATE_DIR" ]]; then
        log_skip "$PRIVATE_DIR exists, skipping the SSH key setup"
    elif [[ -z "$private_url" ]]; then
        log_warn "No private repo URL given (argument or DOTFILES_PRIVATE_URL), skipping the private repo"
    elif [[ ! -t 0 ]]; then
        log_warn "stdin is not a terminal, skipping the SSH key setup and the private repo"
    else
        setup_github_ssh
        if [[ $github_ssh_ready -eq 0 ]]; then
            log_warn "GitHub SSH access skipped, cloning only the public repo over https"
        fi
    fi

    # A clone needs git. On Linux apt just installed it, so the clones follow
    # the key step at once: without an ssh-agent each one asks for the key
    # passphrase again. A fresh Mac only gets git with Homebrew.
    if [[ "$platform" == macos ]]; then
        setup_homebrew
        clone_repositories
    else
        clone_repositories
        setup_homebrew
    fi

    log_info "Handing over to setup.sh"
    exec "$PUBLIC_DIR/setup.sh"
}

main "$@"
