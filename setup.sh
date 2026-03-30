#!/usr/bin/env bash
#
# setup.sh - Dotfiles setup and management
#
# Usage:
#   ./setup.sh                    Interactive setup (select categories)
#   ./setup.sh --all              Install all packages + create symlinks
#   ./setup.sh core cli           Install specific categories only
#   ./setup.sh --link-only        Only create symlinks (no packages)
#   ./setup.sh --packages-only    Only install packages (no symlinks)
#   ./setup.sh --doctor           System health check
#   ./setup.sh --unlink           Remove all managed symlinks
#
# Package categories: core, cli, dev, extra, macos (macOS only)

set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────

readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_PRIVATE="${HOME}/.dotfiles-private"
readonly SYMLINKS_CONF="${DOTFILES_DIR}/symlinks.conf"
readonly PACKAGES_DIR="${DOTFILES_DIR}/packages"

# ── Colors ─────────────────────────────────────────────────────────

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# ── Counters ───────────────────────────────────────────────────────

SYMLINKS_CREATED=0
SYMLINKS_SKIPPED=0
SYMLINKS_FAILED=0
SYMLINKS_EXCLUDED=0
PACKAGES_WARNED=0

# ── Flags ──────────────────────────────────────────────────────────

DRY_RUN=0
FORCE=0
LINK_ONLY=0
PACKAGES_ONLY=0
DO_DOCTOR=0
DO_UNLINK=0
INSTALL_ALL=0
declare -a CATEGORIES=()
declare -a SKIP_GROUPS=()
declare -a ONLY_GROUPS=()

# ── Logging ────────────────────────────────────────────────────────

log_info()    { printf "${BLUE}==>${NC} ${BOLD}%s${NC}\n" "$1"; }
log_success() { printf " ${GREEN}ok${NC} %s\n" "$1"; }
log_skip()    { printf " ${DIM}-- %s${NC}\n" "$1"; }
log_warn()    { printf " ${YELLOW}!!${NC} %s\n" "$1"; }
log_error()   { printf " ${RED}!!${NC} %s\n" "$1" >&2; }
log_header()  { printf "\n${BOLD}%s${NC}\n\n" "$1"; }

# ── Platform Detection ─────────────────────────────────────────────

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

# ── Help ───────────────────────────────────────────────────────────

show_help() {
    cat << 'EOF'
Usage: ./setup.sh [options] [categories...]

Options:
  --all            Install all package categories
  --skip GROUP     Skip symlink group (repeatable, see groups below)
  --only GROUP     Only link these symlink groups (repeatable, mutually exclusive with --skip)
  --link-only      Only create symlinks, skip packages
  --packages-only  Only install packages, skip symlinks
  --doctor         Check system health and symlink integrity
  --unlink         Remove all managed symlinks
  --dry-run        Show what would be done without making changes
  --force          Overwrite existing files and symlinks
  -h, --help       Show this help message

Package categories:
  core      Shell essentials: zsh, git, tmux, sheldon, fzf, zoxide, atuin
  cli       CLI tools: bat, eza, fd, ripgrep, jq, yq, glow, tealdeer, grc
  dev       Dev tools: mise, lazygit, gh, neovim, gitleaks, uv, shellcheck
  extra     Extras: hyperfine, scc, pandoc, yt-dlp, nmap
  macos     macOS apps: Hammerspoon, Karabiner Elements (macOS only)

EOF

    # Show available symlink groups from symlinks.conf
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
  ./setup.sh --link-only --force # Recreate all symlinks
  ./setup.sh --doctor            # Check system health
  ./setup.sh --dry-run --all     # Preview full setup
EOF
}

# ── Argument Parsing ───────────────────────────────────────────────

parse_args() {
    # Load valid group names for validation
    # Virtual groups (handled outside symlinks.conf): espanso
    local -a valid_groups=(espanso)
    if [[ -f "$SYMLINKS_CONF" ]]; then
        while IFS= read -r _g; do
            valid_groups+=("$_g")
        done < <(sed -n 's/^# @group \([a-zA-Z0-9_-]*\).*/\1/p' "$SYMLINKS_CONF")
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)            INSTALL_ALL=1 ;;
            --link-only)      LINK_ONLY=1 ;;
            --packages-only)  PACKAGES_ONLY=1 ;;
            --doctor)         DO_DOCTOR=1 ;;
            --unlink)         DO_UNLINK=1 ;;
            --skip)
                if [[ $# -lt 2 || "$2" == --* ]]; then
                    log_error "--skip requires at least one group name"
                    exit 1
                fi
                shift
                while [[ $# -gt 0 && "$1" != --* ]]; do
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
                continue  # skip outer shift, $1 is already the next flag
                ;;
            --only)
                if [[ $# -lt 2 || "$2" == --* ]]; then
                    log_error "--only requires at least one group name"
                    exit 1
                fi
                shift
                while [[ $# -gt 0 && "$1" != --* ]]; do
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
                continue  # skip outer shift, $1 is already the next flag
                ;;
            --dry-run)        DRY_RUN=1 ;;
            --force)          FORCE=1 ;;
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

# ── Symlink Management ─────────────────────────────────────────────

create_symlink() {
    local source="$1" target="$2"

    # Expand ~ to $HOME in target
    target="${target/#\~/$HOME}"

    # Resolve source to absolute path
    [[ "$source" != /* ]] && source="${DOTFILES_DIR}/${source}"

    # Verify source exists
    if [[ ! -e "$source" ]]; then
        log_warn "Source not found: ${source/#$HOME/~}"
        SYMLINKS_FAILED=$((SYMLINKS_FAILED + 1))
        return 0
    fi

    # Create parent directory
    local target_dir="${target%/*}"
    if [[ ! -d "$target_dir" ]]; then
        if (( DRY_RUN )); then
            log_info "[dry-run] Would create directory: ${target_dir/#$HOME/~}"
        else
            mkdir -p "$target_dir"
        fi
    fi

    # Already correctly linked
    if [[ -L "$target" ]]; then
        local current
        current="$(readlink "$target")"
        if [[ "$current" == "$source" ]]; then
            log_skip "Already linked: ${target/#$HOME/~}"
            SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
            return 0
        fi
        # Different target
        if (( ! FORCE )); then
            log_warn "Exists (different target): ${target/#$HOME/~} -> $current"
            SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
            return 0
        fi
        (( ! DRY_RUN )) && rm -f "$target"
    elif [[ -e "$target" ]]; then
        if (( ! FORCE )); then
            log_warn "Exists (not a symlink): ${target/#$HOME/~}"
            SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
            return 0
        fi
        if [[ -d "$target" ]]; then
            log_warn "Exists as directory: ${target/#$HOME/~} (remove manually to replace with symlink)"
            SYMLINKS_FAILED=$((SYMLINKS_FAILED + 1))
            return 0
        fi
        (( ! DRY_RUN )) && rm -f "$target"
    fi

    if (( DRY_RUN )); then
        log_info "[dry-run] Would link: ${target/#$HOME/~} -> ${source/#$DOTFILES_DIR/}"
    else
        ln -s "$source" "$target"
        log_success "${target/#$HOME/~} -> ${source/#$DOTFILES_DIR/}"
    fi
    SYMLINKS_CREATED=$((SYMLINKS_CREATED + 1))
}

is_group_excluded() {
    local group="$1"
    [[ -z "$group" ]] && return 1  # ungrouped entries are never excluded
    local g
    if [[ ${#ONLY_GROUPS[@]} -gt 0 ]]; then
        for g in "${ONLY_GROUPS[@]}"; do
            [[ "$g" == "$group" ]] && return 1
        done
        return 0  # not in --only list
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

    # Log group filter
    if [[ ${#ONLY_GROUPS[@]} -gt 0 ]]; then
        log_info "Only groups: ${ONLY_GROUPS[*]}"
    elif [[ ${#SKIP_GROUPS[@]} -gt 0 ]]; then
        log_info "Skipping groups: ${SKIP_GROUPS[*]}"
    fi

    local current_group=""

    while IFS= read -r line; do
        # Track @group directives
        if [[ "$line" =~ ^#[[:space:]]*@group[[:space:]]+([a-zA-Z0-9_-]+) ]]; then
            current_group="$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')"
            continue
        fi

        # Skip comments and empty lines
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        # Parse fields (whitespace-separated)
        local source target filter
        read -r source target filter <<< "$line"

        # Apply platform filter
        if [[ -n "${filter:-}" && "$filter" != "$platform" ]]; then
            continue
        fi

        # Apply group filter
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
                    log_info "[dry-run] Would remove: ${target/#$HOME/~}"
                else
                    rm -f "$target"
                    log_success "Removed: ${target/#$HOME/~}"
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

# ── Private Repository Linking ─────────────────────────────────────

link_private_repo() {
    if [[ ! -d "$DOTFILES_PRIVATE" ]]; then
        log_warn "Private dotfiles not found at ${DOTFILES_PRIVATE/#$HOME/~} (skipping)"
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
        log_error "Fix the issue and re-run: ${link_script/#$HOME/~}"
        return 1
    fi
}

# ── Package Installation ──────────────────────────────────────────

select_categories_interactive() {
    local platform="$1"

    log_header "Select package categories to install"

    local -a all_categories=("core" "cli" "dev" "extra")
    [[ "$platform" == "macos" ]] && all_categories+=("macos")

    local desc
    for cat in "${all_categories[@]}"; do
        case "$cat" in
            core)  desc="Shell essentials: zsh, git, tmux, sheldon, fzf, zoxide, atuin" ;;
            cli)   desc="CLI tools: bat, eza, fd, ripgrep, jq, yq, glow, tealdeer, grc" ;;
            dev)   desc="Dev tools: mise, lazygit, gh, neovim, gitleaks, uv, shellcheck" ;;
            extra) desc="Extras: hyperfine, scc, pandoc, yt-dlp, nmap" ;;
            macos) desc="macOS apps: Hammerspoon, Karabiner Elements" ;;
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
    local apt_file="${PACKAGES_DIR}/apt.txt"
    [[ ! -f "$apt_file" ]] && return 0
    command -v apt-get &>/dev/null || return 0

    local -a packages=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        packages+=("$line")
    done < "$apt_file"

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
    local category="$1"
    local brewfile="${PACKAGES_DIR}/Brewfile.${category}"

    if [[ ! -f "$brewfile" ]]; then
        log_warn "No Brewfile for category: $category"
        return 0
    fi

    if ! command -v brew &>/dev/null; then
        log_warn "Homebrew not installed, skipping: $category"
        log_warn "Install Homebrew: https://brew.sh"
        return 0
    fi

    if (( DRY_RUN )); then
        log_info "[dry-run] Would install from Brewfile.$category:"
        sed -n 's/^brew "\(.*\)"/  - \1/p; s/^cask "\(.*\)"/  - \1 (cask)/p' "$brewfile"
        return 0
    fi

    log_info "Installing $category packages (brew)..."
    brew bundle --no-lock --file="$brewfile" || {
        log_warn "Some $category packages may have failed (continuing)"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
    }
}

install_cargo_packages() {
    local cargo_file="${PACKAGES_DIR}/cargo.txt"
    [[ ! -f "$cargo_file" ]] && return 0

    if ! command -v cargo &>/dev/null; then
        log_warn "Cargo not installed, skipping cargo packages"
        return 0
    fi

    local -a packages=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        packages+=("$line")
    done < "$cargo_file"

    [[ ${#packages[@]} -eq 0 ]] && return 0

    if (( DRY_RUN )); then
        log_info "[dry-run] Would install cargo packages: ${packages[*]}"
        return 0
    fi

    log_info "Installing cargo packages..."
    for pkg in "${packages[@]}"; do
        if cargo install --list 2>/dev/null | grep -q "^${pkg} "; then
            log_skip "Already installed: $pkg"
        else
            cargo install "$pkg" 2>/dev/null && log_success "$pkg" || { log_warn "Failed: $pkg"; PACKAGES_WARNED=$((PACKAGES_WARNED + 1)); }
        fi
    done
}

install_github_deb() {
    local name="$1" repo="$2" deb_pattern="$3"

    if command -v "$name" &>/dev/null && (( ! FORCE )); then
        log_skip "Already installed: $name"
        return 0
    fi

    if ! command -v dpkg &>/dev/null; then
        log_warn "dpkg not found, skipping $name (Debian/Ubuntu required)"
        return 0
    fi

    local url
    url="https://github.com/${repo}/releases/latest/download/${deb_pattern}"

    if (( DRY_RUN )); then
        log_info "[dry-run] Would install $name from $url"
        return 0
    fi

    local tmp
    tmp="$(mktemp --suffix=.deb)"

    log_info "Downloading $name from GitHub releases..."
    if ! curl -fsSL -o "$tmp" "$url"; then
        log_warn "Failed to download $name"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
        rm -f "$tmp"
        return 0
    fi

    log_info "Installing $name..."
    if sudo dpkg -i "$tmp"; then
        log_success "$name"
    elif sudo apt-get install -f -y -qq; then
        log_success "$name (deps resolved)"
    else
        log_warn "Failed to install $name"
        PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
    fi
    rm -f "$tmp"
}

install_local_packages() {
    local local_dir="${PACKAGES_DIR}/local"
    [[ -d "$local_dir" ]] || return 0
    command -v brew &>/dev/null || return 0

    local brewfile
    for brewfile in "$local_dir"/Brewfile*; do
        [[ -f "$brewfile" ]] || continue

        local name="${brewfile##*/}"

        if (( DRY_RUN )); then
            log_info "[dry-run] Would install from local/$name:"
            sed -n 's/^brew "\(.*\)"/  - \1/p; s/^cask "\(.*\)"/  - \1 (cask)/p; s/^mas "\(.*\)".*/  - \1 (App Store)/p' "$brewfile"
            continue
        fi

        log_info "Installing local packages ($name)..."
        brew bundle --no-lock --file="$brewfile" || {
            log_warn "Some local packages may have failed (continuing)"
            PACKAGES_WARNED=$((PACKAGES_WARNED + 1))
        }
    done
}

install_linux_extras() {
    local platform="$1"

    # Skip on WSL (espanso runs on the Windows side)
    [[ "$platform" != "linux" ]] && return 0

    # Detect display server for espanso variant
    local espanso_deb="espanso-debian-x11-amd64.deb"
    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        espanso_deb="espanso-debian-wayland-amd64.deb"
    fi

    install_github_deb "espanso" "espanso/espanso" "$espanso_deb"
}

install_packages() {
    local platform="$1"

    if ! command -v brew &>/dev/null; then
        log_warn "Homebrew not found. Most packages require it: https://brew.sh"
    fi

    # Determine categories
    if [[ ${#CATEGORIES[@]} -eq 0 ]] && (( ! INSTALL_ALL )); then
        select_categories_interactive "$platform"
    fi

    if (( INSTALL_ALL )); then
        CATEGORIES=("core" "cli" "dev" "extra")
        [[ "$platform" == "macos" ]] && CATEGORIES+=("macos")
    fi

    [[ ${#CATEGORIES[@]} -eq 0 ]] && return 0

    log_header "Installing packages"

    # System packages first (Linux/WSL)
    if [[ "$platform" == "linux" || "$platform" == "wsl" ]]; then
        install_apt_packages
    fi

    # Brew packages per category
    for category in "${CATEGORIES[@]}"; do
        install_brew_packages "$category"
    done

    # Local packages (symlinked from private repo by link.sh)
    install_local_packages

    # Cargo packages
    install_cargo_packages

    # Linux-only packages (GitHub releases)
    install_linux_extras "$platform"
}

# ── Espanso Config Linking ────────────────────────────────────────
# macOS espanso config path contains spaces (~/Library/Application Support/espanso/)
# which symlinks.conf cannot handle, so this is done separately.

espanso_target_dir() {
    case "$(detect_platform)" in
        macos) printf '%s' "${HOME}/Library/Application Support/espanso" ;;
        linux) printf '%s' "${HOME}/.config/espanso" ;;
        # WSL: espanso runs on the Windows side, no config linking needed
        *)     return 1 ;;
    esac
}

link_espanso_config() {
    # Respect --skip/--only group filtering (virtual group: espanso)
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
        local src="${espanso_source}/${dir}"
        local tgt="${espanso_target}/${dir}"

        if [[ -L "$tgt" ]]; then
            local current
            current="$(readlink "$tgt")"
            if [[ "$current" == "$src" ]]; then
                log_skip "Already linked: ${tgt/#$HOME/~}"
                SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
                continue
            fi
            if (( ! FORCE )); then
                log_warn "Exists (different target): ${tgt/#$HOME/~} -> $current"
                SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
                continue
            fi
            (( ! DRY_RUN )) && rm -f "$tgt"
        elif [[ -d "$tgt" ]]; then
            if (( ! FORCE )); then
                log_warn "Exists as directory: ${tgt/#$HOME/~} (use --force to replace)"
                SYMLINKS_SKIPPED=$((SYMLINKS_SKIPPED + 1))
                continue
            fi
            (( ! DRY_RUN )) && rm -rf "$tgt"
        fi

        if (( DRY_RUN )); then
            log_info "[dry-run] Would link: ${tgt/#$HOME/~} -> ${src/#$DOTFILES_DIR/}"
        else
            mkdir -p "$espanso_target"
            ln -s "$src" "$tgt"
            log_success "${tgt/#$HOME/~} -> ${src/#$DOTFILES_DIR/}"
        fi
        SYMLINKS_CREATED=$((SYMLINKS_CREATED + 1))
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
                    log_info "[dry-run] Would remove: ${tgt/#$HOME/~}"
                else
                    rm -f "$tgt"
                    log_success "Removed: ${tgt/#$HOME/~}"
                fi
            fi
        fi
    done
}

# ── Post-Install ──────────────────────────────────────────────────

post_install() {
    log_header "Post-install"

    # Sheldon plugin lockfile
    if command -v sheldon &>/dev/null; then
        if [[ -f "${HOME}/.config/sheldon/plugins.toml" ]]; then
            if (( DRY_RUN )); then
                log_info "[dry-run] Would run: sheldon lock --update"
            else
                log_info "Updating sheldon plugins..."
                sheldon lock --update 2>/dev/null \
                    && log_success "Sheldon plugins locked" \
                    || log_warn "sheldon lock failed (run manually: sheldon lock --update)"
            fi
        fi
    else
        log_skip "Sheldon not installed"
    fi

    # TPM (Tmux Plugin Manager)
    local tpm_dir="${HOME}/.tmux/plugins/tpm"
    if [[ ! -d "$tpm_dir" ]]; then
        if command -v git &>/dev/null; then
            if (( DRY_RUN )); then
                log_info "[dry-run] Would install TPM"
            else
                log_info "Installing TPM..."
                git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir" 2>/dev/null \
                    && log_success "TPM installed (press prefix+I in tmux to install plugins)" \
                    || log_warn "TPM install failed"
            fi
        fi
    else
        log_skip "TPM already installed"
    fi

    # Neovim plugins
    if command -v nvim &>/dev/null; then
        if [[ -f "${HOME}/.config/nvim/init.lua" ]]; then
            if (( DRY_RUN )); then
                log_info "[dry-run] Would sync neovim plugins"
            else
                log_info "Syncing neovim plugins..."
                nvim --headless "+Lazy! sync" +qa 2>/dev/null \
                    && log_success "Neovim plugins synced" \
                    || log_warn "Neovim plugin sync failed (open nvim to install manually)"
            fi
        fi
    else
        log_skip "Neovim not installed"
    fi

    # Fix file permissions
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

# ── Doctor ────────────────────────────────────────────────────────

check_dir_permissions() {
    local dir="$1" expected="$2" label="$3"
    if [[ -d "$dir" ]]; then
        local perms
        # Linux stat
        perms="$(stat -c '%a' "$dir" 2>/dev/null)" || \
        # macOS stat
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

    # ── Symlinks ──
    printf "${BOLD}Symlinks${NC}\n"
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
                    log_success "${target/#$HOME/~}"
                else
                    log_warn "${target/#$HOME/~} -> wrong target"
                    issues=$((issues + 1))
                fi
            elif [[ -e "$target" ]]; then
                log_warn "${target/#$HOME/~} exists but is not a symlink"
                issues=$((issues + 1))
            else
                log_error "${target/#$HOME/~} missing"
                issues=$((issues + 1))
            fi
        done < "$SYMLINKS_CONF"
    else
        log_error "symlinks.conf not found"
        issues=$((issues + 1))
    fi

    # ── Espanso config (not in symlinks.conf due to spaces in macOS path) ──
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
                        log_success "${_tgt/#$HOME/~}"
                    else
                        log_warn "${_tgt/#$HOME/~} -> wrong target"
                        issues=$((issues + 1))
                    fi
                elif [[ -d "$_tgt" ]]; then
                    log_warn "${_tgt/#$HOME/~} exists but is not a symlink (run setup.sh --link-only --force)"
                    issues=$((issues + 1))
                else
                    log_error "${_tgt/#$HOME/~} missing"
                    issues=$((issues + 1))
                fi
            done
        else
            log_skip "Espanso config not found (populate espanso/local/ first)"
        fi
    fi

    # ── Required tools ──
    printf "\n${BOLD}Required tools${NC}\n"
    local -a required_tools=(git zsh tmux sheldon fzf)
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_success "$tool"
        else
            log_error "$tool not found"
            issues=$((issues + 1))
        fi
    done

    # ── Recommended tools ──
    printf "\n${BOLD}Recommended tools${NC}\n"
    local -a recommended_tools=(bat eza fd rg jq zoxide atuin glow nvim mise lazygit gh uv)
    for tool in "${recommended_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_success "$tool"
        else
            log_warn "$tool not installed"
        fi
    done

    # ── Private repo ──
    printf "\n${BOLD}Private dotfiles${NC}\n"
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

    # ── Permissions ──
    printf "\n${BOLD}Permissions${NC}\n"
    check_dir_permissions "${HOME}/.ssh" "700" "~/.ssh" || issues=$((issues + 1))
    check_dir_permissions "${HOME}/.gnupg" "700" "~/.gnupg" || issues=$((issues + 1))

    # ── Plugin managers ──
    printf "\n${BOLD}Plugin managers${NC}\n"
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

    # ── Summary ──
    printf "\n"
    if (( issues == 0 )); then
        log_info "All checks passed"
    else
        log_warn "$issues issue(s) found"
    fi

    return $(( issues > 0 ? 1 : 0 ))
}

# ── Main ──────────────────────────────────────────────────────────

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
    log_info "Dotfiles: ${DOTFILES_DIR/#$HOME/~}"
    printf "\n"

    # Doctor mode
    if (( DO_DOCTOR )); then
        run_doctor "$platform"
        exit $?
    fi

    # Unlink mode
    if (( DO_UNLINK )); then
        remove_symlinks "$platform"
        unlink_espanso_config
        exit 0
    fi

    # Link private repo first (populates local/ dirs for packages and configs)
    if (( ! PACKAGES_ONLY )); then
        link_private_repo
    fi

    # Install packages (public Brewfiles + local Brewfiles from private repo)
    if (( ! LINK_ONLY )); then
        install_packages "$platform"
    fi

    # Create home symlinks and run post-install
    if (( ! PACKAGES_ONLY )); then
        process_symlinks "$platform"
        link_espanso_config
        if (( ! LINK_ONLY )); then
            post_install
        fi
    fi

    # Summary
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

    if [[ ! -d "$DOTFILES_PRIVATE" ]]; then
        printf "\n"
        log_info "Tip: Clone your private dotfiles to ${DOTFILES_PRIVATE/#$HOME/~}"
        log_info "     Then run: ~/.dotfiles-private/link.sh"
        log_info "     Then run: ./setup.sh --link-only --force"
    fi

    if (( SYMLINKS_FAILED > 0 || PACKAGES_WARNED > 0 )); then
        exit 1
    fi
}

main "$@"
