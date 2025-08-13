# ===============================
# NETWORK FUNCTIONS
# ===============================

# Display local network interfaces with IPs and MAC addresses
ip-local() {
    # Get active interfaces with IPs, MAC addresses, and sort output
    ifconfig | awk '
    /^[a-z]/ { 
        iface = $1; gsub(/:/, "", iface)
        flags = $0
        promisc = (flags ~ /PROMISC/) ? "\033[1;31mPROMISC\033[0m" : ""
        monitor = (flags ~ /MONITOR/) ? "\033[1;33mMONITOR\033[0m" : ""
        modes = promisc monitor
        mac = ""
        iface_name = iface
        # Friendly interface names
        if (iface ~ /^en0/) iface_name = iface " (Wi-Fi/Ethernet)"
        else if (iface ~ /^en[0-9]+/) iface_name = iface " (Ethernet)"
        else if (iface ~ /^utun/) iface_name = iface " (VPN)"
        else if (iface ~ /^awdl/) iface_name = iface " (AirDrop)"
        else if (iface ~ /^bridge/) iface_name = iface " (Bridge)"
    }
    /ether/ { 
        mac = $2
    }
    /inet / && !/127\.0\.0\.1/ { 
        printf "\033[1;36m%-20s\033[0m \033[1;32mIPv4:\033[0m %-39s", iface_name, $2
        if (mac != "") printf " \033[1;90mMAC:\033[0m \033[1;90m%-17s\033[0m", mac
        else printf "     %-17s", ""
        printf "%s\n", modes
    }
    /inet6/ && !/::1/ && !/fe80::/ { 
        printf "\033[1;36m%-20s\033[0m \033[1;35mIPv6:\033[0m %-39s", iface_name, $2
        if (mac != "") printf " \033[1;90mMAC:\033[0m \033[1;90m%-17s\033[0m", mac
        else printf "     %-17s", ""
        printf "%s\n", modes
    }' | sort
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
