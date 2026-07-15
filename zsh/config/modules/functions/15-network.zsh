# ===============================
# NETWORK FUNCTIONS
# ===============================

# Display local network interfaces with IPs and MAC addresses
ip-local() {
    # Use 'ip' command (Linux/WSL) or fallback to 'ifconfig' (macOS)
    if zdotfiles_has_command ip; then
        ip -o addr show | awk '
        BEGIN {
            # Build interface info first
        }
        {
            iface = $2
            type = $3
            addr = $4

            # Skip loopback
            if (iface == "lo") next

            # Friendly interface names
            iface_name = iface
            if (iface ~ /^eth/) iface_name = iface " (Ethernet)"
            else if (iface ~ /^enp/) iface_name = iface " (Ethernet)"
            else if (iface ~ /^wlan/) iface_name = iface " (Wi-Fi)"
            else if (iface ~ /^wlp/) iface_name = iface " (Wi-Fi)"
            else if (iface ~ /^tun/) iface_name = iface " (VPN)"
            else if (iface ~ /^docker/) iface_name = iface " (Docker)"
            else if (iface ~ /^br-/) iface_name = iface " (Bridge)"
            else if (iface ~ /^veth/) iface_name = iface " (Container)"

            # Extract IP without CIDR suffix for display
            split(addr, ip_parts, "/")
            ip_addr = ip_parts[1]

            if (type == "inet") {
                # Skip localhost
                if (ip_addr ~ /^127\./) next
                printf "\033[1;36m%-25s\033[0m \033[1;32mIPv4:\033[0m %s\n", iface_name, ip_addr
            } else if (type == "inet6") {
                # Skip link-local and localhost
                if (ip_addr ~ /^fe80:/ || ip_addr == "::1") next
                printf "\033[1;36m%-25s\033[0m \033[1;35mIPv6:\033[0m %s\n", iface_name, ip_addr
            }
        }' | sort -u
    elif zdotfiles_has_command ifconfig; then
        # Fallback for macOS
        ifconfig | awk '
        /^[a-z]/ {
            iface = $1; gsub(/:/, "", iface)
            mac = ""
            iface_name = iface
            if (iface ~ /^en0/) iface_name = iface " (Wi-Fi/Ethernet)"
            else if (iface ~ /^en[0-9]+/) iface_name = iface " (Ethernet)"
            else if (iface ~ /^utun/) iface_name = iface " (VPN)"
            else if (iface ~ /^awdl/) iface_name = iface " (AirDrop)"
            else if (iface ~ /^bridge/) iface_name = iface " (Bridge)"
        }
        /ether/ { mac = $2 }
        /inet / && !/127\.0\.0\.1/ {
            printf "\033[1;36m%-25s\033[0m \033[1;32mIPv4:\033[0m %-39s", iface_name, $2
            if (mac != "") printf " \033[1;90mMAC:\033[0m \033[1;90m%-17s\033[0m", mac
            printf "\n"
        }
        /inet6/ && !/::1/ && !/fe80::/ {
            printf "\033[1;36m%-25s\033[0m \033[1;35mIPv6:\033[0m %-39s", iface_name, $2
            if (mac != "") printf " \033[1;90mMAC:\033[0m \033[1;90m%-17s\033[0m", mac
            printf "\n"
        }' | sort
    else
        zdotfiles_error "Neither 'ip' nor 'ifconfig' found"
        return 1
    fi
}

# Ping-sweep the local /24 and list responders' IP + MAC from ARP/neighbour table
lan-scan() {
    setopt LOCAL_OPTIONS LOCAL_TRAPS NO_MONITOR NO_NOTIFY
    local prefix iface tmpdir arp_dump ip_addr mac f ping_wait oui_db oui vendor p
    local gateway first_octet gw_tag vm_tag rand_tag self_tag dup_tag tags if_name ip_found s
    local -a live_ips octets self_ips
    local -A mac_by_ip vendor_by_ip mac_count

    while (( $# > 0 )); do
        case "$1" in
            -h|--help)
                cat <<'USAGE'
lan-scan - Ping-sweep the local /24 and list responders with IP + MAC

Usage: lan-scan [-h] [-l] [-i <interface>] [prefix]

Options:
  -h, --help              Show this help
  -l, --list-interfaces   List available interfaces with IPv4 and exit
  -i, --interface IFACE   Derive /24 prefix from IFACE instead of the default route

Arguments:
  prefix   /24 prefix (e.g. 192.168.1) or a full IPv4 (last octet is stripped).
           If omitted, auto-detected from the chosen interface.

Output tags:
  [gw]     Default gateway for the scanning host
  [self]   An IP bound to an interface on the scanning host
  [VM]     Vendor string matches a known hypervisor (Proxmox/VMware/QEMU/VirtualBox/Xen/Hyper-V/Parallels)
  [rand]   Locally-administered (randomized/private) MAC; vendor lookup will not match
  [dup]    Same MAC observed on more than one IP in this scan (stale lease or misconfig)
USAGE
                return 0
                ;;
            -l|--list-interfaces)
                local if_name if_ip
                if zdotfiles_is_macos; then
                    for if_name in $(ifconfig -l); do
                        [[ "$if_name" == "lo0" ]] && continue
                        if_ip=$(ipconfig getifaddr "$if_name" 2>/dev/null)
                        [[ -n "$if_ip" ]] && printf "%-10s %s\n" "$if_name" "$if_ip"
                    done
                elif zdotfiles_has_command ip; then
                    ip -4 -o addr show scope global 2>/dev/null | awk '{printf "%-10s %s\n", $2, $4}'
                else
                    zdotfiles_error "Cannot list interfaces on this platform"
                    return 1
                fi
                return 0
                ;;
            -i|--interface)
                [[ -z "$2" ]] && { zdotfiles_error "$1 requires an interface name"; return 1; }
                iface="$2"
                shift 2
                ;;
            --)
                shift
                [[ -n "$1" ]] && prefix="$1"
                break
                ;;
            -*)
                zdotfiles_error "Unknown option: $1"
                return 1
                ;;
            *)
                prefix="$1"
                shift
                ;;
        esac
    done

    if [[ -z "$prefix" ]]; then
        if [[ -z "$iface" ]]; then
            if zdotfiles_is_macos; then
                iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
            elif zdotfiles_has_command ip; then
                iface=$(ip route show default 2>/dev/null | awk '/^default/ {print $5; exit}')
            fi
        fi
        if [[ -n "$iface" ]]; then
            if zdotfiles_is_macos; then
                prefix=$(ipconfig getifaddr "$iface" 2>/dev/null)
            elif zdotfiles_has_command ip; then
                prefix=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
            fi
        fi
    fi

    # Strip last octet only when a full IPv4 was provided/detected
    if [[ "$prefix" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        prefix="${prefix%.*}"
    fi

    if ! [[ "$prefix" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        zdotfiles_error "Could not determine /24 prefix (try -i <iface> or pass one explicitly; see -h)"
        return 1
    fi

    echo "Scanning ${prefix}.0/24${iface:+ via $iface}..." >&2

    # -W on macOS is milliseconds, on Linux is seconds
    if zdotfiles_is_macos; then
        ping_wait=500
    else
        ping_wait=1
    fi

    tmpdir=$(mktemp -d 2>/dev/null) || { zdotfiles_error "mktemp failed"; return 1; }
    trap "rm -rf '$tmpdir'" EXIT INT TERM

    # xargs -P bounds concurrency and avoids zsh job-control noise from 254 &s
    printf '%s\n' {1..254} | xargs -n1 -P 64 -I{} \
        sh -c "ping -c1 -W${ping_wait} ${prefix}.{} >/dev/null 2>&1 && : > ${tmpdir}/{}"

    for f in "$tmpdir"/*(N); do
        live_ips+=("${prefix}.${f:t}")
    done

    if (( ${#live_ips[@]} == 0 )); then
        echo "No responders on ${prefix}.0/24" >&2
        return 0
    fi

    if zdotfiles_has_command ip; then
        arp_dump=$(ip neigh 2>/dev/null)
    elif zdotfiles_has_command arp; then
        arp_dump=$(arp -an 2>/dev/null)
    else
        zdotfiles_error "Neither 'ip' nor 'arp' available"
        return 1
    fi

    # OUI vendor DB shipped with nmap; graceful blank if unavailable
    for p in /opt/homebrew/share/nmap/nmap-mac-prefixes \
             /usr/local/share/nmap/nmap-mac-prefixes \
             /usr/share/nmap/nmap-mac-prefixes; do
        [[ -r "$p" ]] && { oui_db="$p"; break; }
    done

    # Default gateway (used to tag the [gw] row); only meaningful when scanning the default-route subnet
    if zdotfiles_is_macos; then
        gateway=$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}')
    elif zdotfiles_has_command ip; then
        gateway=$(ip route show default 2>/dev/null | awk '/^default/ {print $3; exit}')
    fi

    # Local IPs (for [self] tagging)
    if zdotfiles_is_macos; then
        for if_name in $(ifconfig -l); do
            [[ "$if_name" == "lo0" ]] && continue
            ip_found=$(ipconfig getifaddr "$if_name" 2>/dev/null)
            [[ -n "$ip_found" ]] && self_ips+=("$ip_found")
        done
    elif zdotfiles_has_command ip; then
        self_ips=("${(@f)$(ip -4 -o addr show scope global 2>/dev/null | awk '{sub(/\/.*/, "", $4); print $4}')}")
    fi

    # Pass 1: look up MAC + vendor per live IP, count MAC occurrences for [dup] detection
    for ip_addr in "${live_ips[@]}"; do
        if zdotfiles_has_command ip; then
            mac=$(print -r -- "$arp_dump" | awk -v ip="$ip_addr" '$1 == ip && $5 ~ /:/ {print $5; exit}')
        else
            mac=$(print -r -- "$arp_dump" | awk -v ip="($ip_addr)" '$2 == ip && !/incomplete/ {print $4; exit}')
        fi
        mac_by_ip[$ip_addr]="$mac"
        [[ "$mac" == *:*:*:*:*:* ]] && mac_count[$mac]=$(( ${mac_count[$mac]:-0} + 1 ))

        vendor=""
        if [[ "$mac" == *:*:*:*:*:* && -n "$oui_db" ]]; then
            octets=(${(s.:.)mac})
            oui=$(printf "%02X%02X%02X" "0x${octets[1]}" "0x${octets[2]}" "0x${octets[3]}" 2>/dev/null)
            [[ -n "$oui" ]] && vendor=$(awk -v o="$oui" '$1 == o {$1=""; sub(/^ /, ""); print; exit}' "$oui_db")
        fi
        vendor_by_ip[$ip_addr]="$vendor"
    done

    # Pass 2: build raw rows (TSV) with cross-row tags, sort, then format
    local -a raw_rows
    for ip_addr in "${live_ips[@]}"; do
        mac="${mac_by_ip[$ip_addr]}"
        vendor="${vendor_by_ip[$ip_addr]}"

        rand_tag=""
        if [[ "$mac" == *:*:*:*:*:* ]]; then
            octets=(${(s.:.)mac})
            # U/L bit (bit 1 of first octet) set => locally-administered / randomized MAC
            first_octet="${octets[1]}"
            (( (0x${first_octet} & 2) != 0 )) && rand_tag="[rand]"
        fi

        gw_tag=""
        [[ -n "$gateway" && "$ip_addr" == "$gateway" ]] && gw_tag="[gw]"

        self_tag=""
        for s in "${self_ips[@]}"; do
            [[ "$ip_addr" == "$s" ]] && { self_tag="[self]"; break; }
        done

        dup_tag=""
        [[ "$mac" == *:*:*:*:*:* ]] && (( ${mac_count[$mac]:-0} > 1 )) && dup_tag="[dup]"

        vm_tag=""
        case "$vendor" in
            *Proxmox*|*VMware*|*VirtualBox*|*QEMU*|*Xen*|*"Hyper-V"*|*Parallels*) vm_tag="[VM]" ;;
        esac

        tags="${gw_tag}${self_tag}${vm_tag}${rand_tag}${dup_tag}"
        raw_rows+=("${ip_addr}"$'\t'"${mac:-?}"$'\t'"${vendor}"$'\t'"${tags}")
    done

    # Colors only when stdout is a TTY (so pipes/redirections get clean data)
    local cyan="" gray="" reset=""
    if [[ -t 1 ]]; then
        cyan=$'\033[1;36m'
        gray=$'\033[1;90m'
        reset=$'\033[0m'
    fi

    local row_ip row_mac row_vendor row_tags
    printf '%s\n' "${raw_rows[@]}" | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n | while IFS=$'\t' read -r row_ip row_mac row_vendor row_tags; do
        printf "${cyan}%-15s${reset} ${gray}%-17s${reset} %-35s %s\n" "$row_ip" "$row_mac" "$row_vendor" "$row_tags"
    done

    echo "${#live_ips[@]} responders on ${prefix}.0/24" >&2
}

# Provider adapters for net-check. Each prints one TSV row
# (provider, latency_ms, down_mbps, up_mbps, quality) or returns non-zero.

_net_check_cloudflare() {
    local json
    # --auto-save false: the CLI persists a run history by default, and a shell
    # helper should not accrete state on disk without being asked to.
    json=$(cloudflare-speed-cli --json --auto-save false 2>/dev/null) || return 1
    # Absent fields become "?" rather than 0, so a provider that failed to
    # measure is never rendered as having measured zero.
    print -r -- "$json" | jq -r '
        [ "Cloudflare",
          (.idle_latency.median_ms // "?"),
          (.download.mbps // "?"),
          (.upload.mbps // "?"),
          "bufferbloat " + (.connection_quality.bufferbloat_grade // "?")
        ] | @tsv' 2>/dev/null
}

_net_check_apple() {
    local json
    # networkQuality reports throughput in bits/s, the table shows Mbit/s
    local -r bits_per_mbit=1000000
    # -s forces upload and download to run sequentially. By default they run at
    # once, so the upload competes with the download and reads far under line
    # speed (28-160 Mbps against a 624 Mbps downstream, against 257 with -s,
    # which matches Cloudflare within 1%). -s also replaces the single
    # top-level responsiveness field that parallel mode emits with per-phase
    # dl_/ul_responsiveness, so RPM is read from those.
    json=$(networkQuality -s -c 2>/dev/null) || return 1
    print -r -- "$json" | jq -r --argjson mbit "$bits_per_mbit" '
        [ "Apple",
          (.base_rtt // "?"),
          (if .dl_throughput then .dl_throughput / $mbit else "?" end),
          (if .ul_throughput then .ul_throughput / $mbit else "?" end),
          "RPM " + (if .dl_responsiveness and .ul_responsiveness
                    then (.dl_responsiveness | round | tostring) + "/"
                       + (.ul_responsiveness | round | tostring)
                    else "?" end)
        ] | @tsv' 2>/dev/null
}

# Measure internet throughput, latency and bufferbloat, optionally across providers
#
# Providers measure deliberately different paths (Cloudflare's anycast edge vs
# Apple's CDN) and differ in server placement, stream count and congestion
# control, so they disagree for legitimate reasons rather than by error. --all
# therefore prints every row and summarises with the max, never the mean:
# throughput error is one-sided, since TCP slow start, cross-traffic and
# per-flow shapers can only depress a sample and never inflate one. A
# cross-provider average is thus biased low by construction and additionally
# averages over unrelated bottlenecks. See MacMillan et al., "Best Practices for
# Collecting Speed Test Data" (2022); Cloudflare's own client reports p90.
net-check() {
    local all=0 provider row attempted=0
    local -a providers rows
    # Flag a cross-provider gap only once it exceeds what a single provider
    # varies by between runs on a consumer link (Wi-Fi swings by ~3x), below
    # which a "disagreement" is just noise being reported as a finding.
    local -r divergence_ratio=2
    # A saturating test leaves the link perturbed, so whatever runs next reads
    # low: 157-207 Mbps back-to-back against 490-624 standalone. A gap this long
    # brings the providers within 1-10% of each other, against the 2.9x split
    # they showed back-to-back. Sufficient at this length, not shown minimal.
    local -r settle_seconds=10

    while (( $# > 0 )); do
        case "$1" in
            -h|--help)
                cat <<'USAGE'
net-check - Internet throughput, latency and bufferbloat

Usage: net-check [-h] [-a]

Options:
  -h, --help   Show this help
  -a, --all    Run every available provider and compare

Providers are auto-detected. Without -a only the first available runs:
  Cloudflare   cloudflare-speed-cli (brew install cloudflare-speed-cli)
  Apple        /usr/bin/networkQuality (built in on macOS)

With -a providers run sequentially, never concurrently, and with a settle gap
between them: throughput tests saturate the link by design, so running them
at once would make each report a fraction of the true capacity, and running
them back-to-back depresses whichever goes second. Results are summarised
with the max, not the mean (see the comment above this function for why).

Providers routinely disagree. They place servers differently (Cloudflare's
anycast edge vs Apple's CDN), open different numbers of streams and use
different congestion control, so a spread is usually a real difference
between paths rather than a faulty test. It can also mean an unstable link,
which is common on Wi-Fi: re-run before drawing conclusions.

Unmeasured values read "?" and are never summarised as zero.

Quality column:
  bufferbloat  Cloudflare's A-F grade for latency increase under load
  RPM          Responsiveness under load (IETF draft), as download/upload.
               Sequential mode measures it once per phase, so the two figures
               are the round-trips per minute seen while each direction was
               saturated.
USAGE
                return 0
                ;;
            -a|--all)
                all=1
                shift
                ;;
            -*)
                zdotfiles_error "Unknown option: $1"
                return 1
                ;;
            *)
                zdotfiles_error "Unexpected argument: $1"
                return 1
                ;;
        esac
    done

    if ! zdotfiles_has_command jq; then
        zdotfiles_error "net-check requires jq"
        return 1
    fi

    # Cloudflare first: its anycast edge keeps RTT low, and low RTT is the
    # regime where a single measurement is most trustworthy.
    zdotfiles_has_command cloudflare-speed-cli && providers+=(cloudflare)
    zdotfiles_is_macos && [[ -x /usr/bin/networkQuality ]] && providers+=(apple)

    if (( ${#providers[@]} == 0 )); then
        zdotfiles_error "No provider found (brew install cloudflare-speed-cli)"
        return 1
    fi

    (( all )) || providers=("${providers[1]}")

    for provider in "${providers[@]}"; do
        if (( attempted )); then
            echo "Settling ${settle_seconds}s..." >&2
            sleep "$settle_seconds"
        fi
        echo "Testing ${provider}..." >&2
        # An adapter can emit nothing and still exit 0 (empty input parses
        # cleanly), so an empty row counts as a failure rather than a data row.
        row=$(_net_check_${provider}) || row=""
        if [[ -z "$row" ]]; then
            zdotfiles_error "${provider} test failed"
            continue
        fi
        # Only a test that actually ran perturbs the link, so only a test that
        # ran makes the next one pay the settle gap.
        attempted=1
        rows+=("$row")
    done

    (( ${#rows[@]} == 0 )) && return 1

    # Colors only when stdout is a TTY (so pipes/redirections get clean data)
    local cyan="" gray="" bold="" reset=""
    if [[ -t 1 ]]; then
        cyan=$'\033[1;36m'
        gray=$'\033[1;90m'
        bold=$'\033[1m'
        reset=$'\033[0m'
    fi

    printf '%s\n' "${rows[@]}" | awk -F'\t' \
        -v cyan="$cyan" -v gray="$gray" -v bold="$bold" -v reset="$reset" \
        -v ratio="$divergence_ratio" '
    function fmt(v, f) { return (v == "?" || v == "") ? "?" : sprintf(f, v) }
    BEGIN {
        printf "%s%-12s %9s %11s %10s  %s%s\n", bold, "PROVIDER", "LATENCY", "DOWN Mbps", "UP Mbps", "QUALITY", reset
    }
    {
        printf "%s%-12s%s %9s %11s %10s  %s%s%s\n", cyan, $1, reset, fmt($2, "%.1f ms"), fmt($3, "%.2f"), fmt($4, "%.2f"), gray, $5, reset
        n++
        # Unmeasured values are excluded rather than counted as zero, which
        # would both invent a data point and mask the spread via the min guard.
        if ($3 != "?") { if (nd++ == 0) max_down = min_down = $3
                         else { if ($3 > max_down) max_down = $3; if ($3 < min_down) min_down = $3 } }
        if ($4 != "?") { if (nu++ == 0) max_up = min_up = $4
                         else { if ($4 > max_up) max_up = $4; if ($4 < min_up) min_up = $4 } }
    }
    END {
        if (n < 2) exit
        # Each column maxes over only the providers that measured it, and those
        # counts can differ, so one number would misreport the other column.
        if (nd == nu) label = sprintf("max of %d providers", nd)
        else label = sprintf("max of %d/%d providers (down/up)", nd, nu)
        printf "\n%s%-12s%s %9s %11s %10s  %s%s%s\n", bold, "best", reset, "", fmt(nd ? max_down : "?", "%.2f"), fmt(nu ? max_up : "?", "%.2f"), gray, label, reset
        if (nd >= 2 && min_down > 0 && max_down / min_down > ratio)
            printf "%s! providers disagree %.1fx on download (see -h)%s\n", gray, max_down / min_down, reset
        if (nu >= 2 && min_up > 0 && max_up / min_up > ratio)
            printf "%s! providers disagree %.1fx on upload (see -h)%s\n", gray, max_up / min_up, reset
    }'
}

# Only define network functions if required tools are available
if zdotfiles_has_command tcpdump; then
    # Network packet sniffing function
    sniff() {
        if [[ $# -eq 0 ]]; then
            echo "Usage: sniff <port_number>"
            echo "Example: sniff 80"
            return 1
        fi

        # Validate port number
        if ! [[ "$1" =~ ^[0-9]+$ ]] || (( $1 < 1 || $1 > 65535 )); then
            zdotfiles_error "Invalid port number: $1 (must be 1-65535)"
            return 1
        fi

        echo "Starting packet capture on port $1..."
        sudo tcpdump -i any port "$1"
    }
fi

if zdotfiles_has_command nmap; then
    # Network scanning function
    nscan() {
        if [[ $# -eq 0 ]]; then
            echo "Usage: nscan <target>"
            echo "Example: nscan 192.168.1.1"
            return 1
        fi

        # Basic target validation (prevent command injection)
        if [[ "$1" =~ "[;&|]" ]]; then
            zdotfiles_error "Invalid characters in target: $1"
            return 1
        fi

        echo "Scanning target: $1"
        sudo nmap -sS -Pn "$1"
    }
fi
