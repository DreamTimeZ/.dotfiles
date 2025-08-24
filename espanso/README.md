# Espanso Text Expansion

Personal text expansion configurations (git-ignored for privacy).

## Setup

Copy templates and customize:

```bash
cd ~/.dotfiles/espanso/templates
for f in *.template; do cp "$f" "../local/${f%.template}"; done
```

Edit your personal snippets in `local/` directory.

Symlinks are created automatically during installation.
