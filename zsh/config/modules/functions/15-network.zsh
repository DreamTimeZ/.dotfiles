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
        if [[ "$1" =~ [;&|] ]]; then
            zdotfiles_error "Invalid characters in target: $1"
            return 1
        fi
        
        echo "Scanning target: $1"
        sudo nmap -sS -Pn "$1"
    }
fi