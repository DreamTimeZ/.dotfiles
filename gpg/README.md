# GPG

GnuPG config, linked into `~/.gnupg/` by `setup.sh` (group `gpg`, skip with `--skip gpg`).

| File | Active settings |
| --- | --- |
| `gpg.conf` | Long key IDs with fingerprints, AES256/SHA512 preferences, no version or comment in armored output |
| `gpg-agent.conf` | `pinentry-tty`, cache 10 minutes (max 2 hours), loopback pinentry allowed |
| `common.conf` | `use-keyboxd` |
| `dirmngr.conf` | None, commented-out templates only |
| `scdaemon.conf` | `card-timeout 5`, the rest is commented-out templates |
| `gpgsm.conf` | None, commented-out templates only |

## Traps

- `setup.sh` does not install `gnupg`. `brew install gnupg` also pulls in `pinentry`.
- `pinentry-program` is the Apple Silicon Homebrew path (`/opt/homebrew/opt/pinentry/bin/pinentry-tty`), linked on every platform. On Intel macOS or Linux it does not exist and passphrase prompts fail until it is changed.
- `gpg-backup` exports with `--pinentry-mode loopback`, so it needs `allow-loopback-pinentry`.

## Commands

```bash
gpg-connect-agent reloadagent /bye   # apply gpg-agent.conf changes
gpgconf --reload dirmngr             # apply dirmngr.conf changes
gpg-backup                           # back up keys and trust database (bin/gpg-backup)
gpg-restore                          # restore from a backup (bin/gpg-restore)
```
