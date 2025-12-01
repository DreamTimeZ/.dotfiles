# GPG Configuration

This directory contains GPG (GnuPG) configuration files for encryption, signing, and key management.

## Files

### Core Configuration Files

- **gpg.conf** - Main GPG configuration with security preferences
- **gpg-agent.conf** - GPG agent settings for key caching and pinentry
- **common.conf** - Common settings for GnuPG components (keyboxd)

### Optional Configuration Files (Template)

- **dirmngr.conf** - Network/keyserver settings (CRLs, keyserver access)
- **scdaemon.conf** - Smartcard daemon settings (YubiKey, OpenPGP cards)
- **gpgsm.conf** - S/MIME and X.509 certificate handling

### Local Overrides

- **local/** - Machine-specific overrides (gitignored, managed by private dotfiles)

## Installation

### Required Configuration

Link the core configs to your `~/.gnupg` directory:

```bash
ln -sf ~/.dotfiles/gpg/gpg.conf ~/.gnupg/gpg.conf
ln -sf ~/.dotfiles/gpg/gpg-agent.conf ~/.gnupg/gpg-agent.conf
ln -sf ~/.dotfiles/gpg/common.conf ~/.gnupg/common.conf
```

### Optional Configuration

Link optional configs only if you need them:

```bash
# If you use keyservers or need network/CRL settings
ln -sf ~/.dotfiles/gpg/dirmngr.conf ~/.gnupg/dirmngr.conf

# If you use smartcards (YubiKey, OpenPGP cards, etc.)
ln -sf ~/.dotfiles/gpg/scdaemon.conf ~/.gnupg/scdaemon.conf

# If you use S/MIME or X.509 certificates
ln -sf ~/.dotfiles/gpg/gpgsm.conf ~/.gnupg/gpgsm.conf
```

### Apply Changes

After linking, reload the GPG components:

```bash
gpg-connect-agent reloadagent /bye
gpgconf --reload dirmngr
```

## Configuration Highlights

### gpg.conf

- Uses long key ID format (64-bit) for better security
- Strong cipher preferences (AES256, AES192, AES)
- Strong digest preferences (SHA512, SHA384, SHA256)
- Removes version and comments from output
- Shows key validity information

### gpg-agent.conf

- Terminal-based pinentry (no GUI)
- 10-minute default cache timeout
- 2-hour maximum cache timeout
- Loopback pinentry support for automation
- SSH support (commented out, enable if needed)

### common.conf

- Uses modern keyboxd for key storage

### dirmngr.conf (Optional)

- Template for keyserver configuration (keys.openpgp.org recommended)
- Proxy and Tor support settings
- Network timeout configuration
- Most settings commented out by default

### scdaemon.conf (Optional)

- Template for smartcard/YubiKey configuration
- Card timeout settings (5 seconds default)
- Pinpad support configuration
- Most settings commented out by default

### gpgsm.conf (Optional)

- Template for S/MIME and X.509 certificate handling
- CRL and OCSP validation settings
- Compliance mode options
- Most settings commented out by default

## Security Notes

- **Private Keys**: Never commit private keys or keyrings to version control
- **Pinentry**: Configured for terminal use; adjust if you prefer GUI pinentry
- **Cache Timeouts**: Adjust based on your security/convenience balance
- **SSH Support**: Enable in gpg-agent.conf if using GPG for SSH authentication

## Backup and Restore

Use the included scripts:

- `bin/gpg-backup` - Backup GPG keys and trust database
- `bin/gpg-restore` - Restore GPG keys from backup

## Useful Commands

```bash
# List keys
gpg --list-keys
gpg --list-secret-keys

# Generate new key
gpg --full-generate-key

# Export public key
gpg --export --armor <key-id> > public-key.asc

# Import key
gpg --import key.asc

# Edit key (trust, sign, etc.)
gpg --edit-key <key-id>

# Reload agent after config changes
gpg-connect-agent reloadagent /bye

# Kill agent (will restart on next use)
gpgconf --kill gpg-agent
```

## Version

Configurations tested with GnuPG 2.4.x (modern standards as of 2024/2025)
