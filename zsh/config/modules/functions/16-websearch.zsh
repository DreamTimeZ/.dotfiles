# ===============================
# WEB SEARCH FUNCTIONS
# ===============================
# Quick search shortcuts for common sites from the terminal
# Opens searches in your default browser (cross-platform)

# ----- Browser Detection -----

# Open URL in default browser (cross-platform)
# Usage: _zdotfiles_open_url "https://example.com"
_zdotfiles_open_url() {
    local url="$1"
    [[ -z "$url" ]] && return 1

    # Use $BROWSER if explicitly set and valid
    if [[ -n "$BROWSER" ]]; then
        if zdotfiles_has_command "${BROWSER%% *}"; then
            "$BROWSER" "$url"
            return $?
        else
            zdotfiles_warn "\$BROWSER ($BROWSER) not found, using platform default"
        fi
    fi

    # Platform-specific openers
    if zdotfiles_is_macos; then
        open "$url"
    elif zdotfiles_is_wsl; then
        # Prefer firefox/chrome functions if available (from WSL launchers)
        if (( ${+functions[firefox]} )); then
            firefox "$url"
        elif (( ${+functions[chrome]} )); then
            chrome "$url"
        else
            # Fallback to cmd.exe start
            /mnt/c/Windows/System32/cmd.exe /c start "" "$url" >/dev/null 2>&1 &!
        fi
    else
        # Linux: use xdg-open
        if zdotfiles_has_command xdg-open; then
            xdg-open "$url" &>/dev/null &!
        else
            zdotfiles_error "No browser found. Set \$BROWSER or install xdg-utils"
            return 1
        fi
    fi
}

# ----- Search Engine Functions -----

# URL-encode a string for use in query parameters
# Usage: _zdotfiles_urlencode "foo & bar" → "foo%20%26%20bar"
_zdotfiles_urlencode() {
    local string="$1"
    local encoded=""
    local char

    for (( i=0; i<${#string}; i++ )); do
        char="${string:$i:1}"
        case "$char" in
            [a-zA-Z0-9.~_-]) encoded+="$char" ;;
            ' ') encoded+='+' ;;
            *) encoded+=$(printf '%%%02X' "'$char") ;;
        esac
    done
    print -r -- "$encoded"
}

# Generic web search helper
# Usage: _websearch <base_url> [query...]
# If no query, opens the base site
_websearch() {
    local base_url="$1"
    shift

    if [[ $# -eq 0 ]]; then
        # No query - open base site (strip query params)
        _zdotfiles_open_url "${base_url%%\?*}"
    else
        # URL-encode each argument and join with +
        local -a encoded_parts
        local arg
        for arg in "$@"; do
            encoded_parts+=("$(_zdotfiles_urlencode "$arg")")
        done
        local query="${(j:+:)encoded_parts}"
        _zdotfiles_open_url "${base_url}${query}"
    fi
}

# ----- Search Shortcuts -----

# GitHub search
# Usage: ghs [query] | ghs react hooks
ghs() {
    if [[ "$1" == (-h|--help) ]]; then
        echo "Usage: ghs [query]"
        echo "Search GitHub repositories and code"
        echo ""
        echo "Examples:"
        echo "  ghs                    # Open github.com"
        echo "  ghs react hooks        # Search for 'react hooks'"
        echo "  ghs 'language:rust'    # Search with filters"
        return 0
    fi
    _websearch "https://github.com/search?q=" "$@"
}

# Google search
# Usage: google [query] | google how to exit vim
google() {
    if [[ "$1" == (-h|--help) ]]; then
        echo "Usage: google [query]"
        echo "Search Google"
        echo ""
        echo "Examples:"
        echo "  google                 # Open google.com"
        echo "  google how to exit vim # Search query"
        return 0
    fi
    _websearch "https://www.google.com/search?q=" "$@"
}

# YouTube search
# Usage: yt [query] | yt lofi beats
yt() {
    if [[ "$1" == (-h|--help) ]]; then
        echo "Usage: yt [query]"
        echo "Search YouTube"
        echo ""
        echo "Examples:"
        echo "  yt                     # Open youtube.com"
        echo "  yt lofi beats          # Search videos"
        return 0
    fi
    _websearch "https://www.youtube.com/results?search_query=" "$@"
}

# Stack Overflow search
# Usage: so [query] | so python async await
so() {
    if [[ "$1" == (-h|--help) ]]; then
        echo "Usage: so [query]"
        echo "Search Stack Overflow"
        echo ""
        echo "Examples:"
        echo "  so                     # Open stackoverflow.com"
        echo "  so python async await  # Search questions"
        return 0
    fi
    _websearch "https://stackoverflow.com/search?q=" "$@"
}

# NPM package search
# Usage: npm-search [query] | npm-search lodash
npm-search() {
    if [[ "$1" == (-h|--help) ]]; then
        echo "Usage: npm-search [query]"
        echo "Search npm packages"
        echo ""
        echo "Examples:"
        echo "  npm-search             # Open npmjs.com"
        echo "  npm-search lodash      # Search packages"
        return 0
    fi
    _websearch "https://www.npmjs.com/search?q=" "$@"
}

# PyPI package search
# Usage: pypi [query] | pypi requests
pypi() {
    if [[ "$1" == (-h|--help) ]]; then
        echo "Usage: pypi [query]"
        echo "Search Python packages on PyPI"
        echo ""
        echo "Examples:"
        echo "  pypi                   # Open pypi.org"
        echo "  pypi requests          # Search packages"
        return 0
    fi
    _websearch "https://pypi.org/search/?q=" "$@"
}

# Google Scholar search
# Usage: scholar [query] | scholar machine learning
scholar() {
    if [[ "$1" == (-h|--help) ]]; then
        echo "Usage: scholar [query]"
        echo "Search Google Scholar for academic papers"
        echo ""
        echo "Examples:"
        echo "  scholar                # Open scholar.google.com"
        echo "  scholar machine learning"
        return 0
    fi
    _websearch "https://scholar.google.com/scholar?q=" "$@"
}

# Semantic Scholar search
# Usage: semscholar [query] | semscholar neural networks
semscholar() {
    if [[ "$1" == (-h|--help) ]]; then
        echo "Usage: semscholar [query]"
        echo "Search Semantic Scholar for academic papers"
        echo ""
        echo "Examples:"
        echo "  semscholar             # Open semanticscholar.org"
        echo "  semscholar neural networks"
        return 0
    fi
    _websearch "https://www.semanticscholar.org/search?q=" "$@"
}

# Internet Archive search
# Usage: xarchive [query] | xarchive "old software"
xarchive() {
    if [[ "$1" == (-h|--help) ]]; then
        echo "Usage: xarchive [query]"
        echo "Search the Internet Archive (archive.org)"
        echo ""
        echo "Examples:"
        echo "  xarchive               # Open archive.org"
        echo "  xarchive old software  # Search archives"
        return 0
    fi
    _websearch "https://archive.org/search?query=" "$@"
}

# Docker Hub search
# Usage: dockerhub [query] | dockerhub nginx
dockerhub() {
    if [[ "$1" == (-h|--help) ]]; then
        echo "Usage: dockerhub [query]"
        echo "Search Docker Hub images"
        echo ""
        echo "Examples:"
        echo "  dockerhub              # Open hub.docker.com"
        echo "  dockerhub nginx        # Search images"
        return 0
    fi
    _websearch "https://hub.docker.com/search?q=" "$@"
}
