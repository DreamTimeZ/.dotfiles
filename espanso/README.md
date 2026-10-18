# Espanso

Cross-platform text expander. Docs: <https://espanso.org/docs/>

```text
espanso/
├── templates/                  Starter configs
│   ├── default.yml.template    Global settings (toggle key, backend)
│   └── base.yml.template       Example matches (dates, markdown, shell)
└── local/                      Git-ignored, filled from the private repo
    ├── config/                 App-level settings (*.yml)
    └── match/                  Trigger definitions (*.yml)
```

`setup.sh` links `local/config` and `local/match` into the espanso config dir (`~/Library/Application Support/espanso` on macOS, `~/.config/espanso` on Linux). On WSL espanso runs on the Windows side: run `temporary-link.bat` from the private repo to create the Windows symlinks (it requests admin rights itself).

Without the private repo, start from the templates:

```bash
cd ~/.dotfiles/espanso
cp templates/default.yml.template local/config/default.yml
cp templates/base.yml.template local/match/base.yml
```
