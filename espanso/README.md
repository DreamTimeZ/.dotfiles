# Espanso

Cross-platform text expander. Docs: <https://espanso.org/docs/>

## Structure

```
espanso/
├── templates/          Starter configs, copy into local/ to use
│   ├── default.yml     Global espanso settings
│   └── base.yml        Example matches (dates, markdown, shell)
└── local/              Git-ignored, personal config lives here
    ├── config/         App-level settings (toggle key, backend, OS filters)
    └── match/          Trigger definitions (*.yml)
```

## Quick Start

Copy templates and customize:

```bash
cd ~/.dotfiles/espanso/templates
for f in *.template; do cp "$f" "../local/${f%.template}"; done
```

Then edit files in `local/` to add your own triggers and settings.
