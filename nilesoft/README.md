# Nilesoft Shell

Windows context menu customizer. Docs: <https://nilesoft.org/docs/>

## Structure

Installed at `%ProgramFiles%\Nilesoft Shell`:

```
Nilesoft Shell/
├── shell.nss               * Entrypoint — settings, imports, menu items
└── imports/
    ├── theme.nss           * Colors, fonts, appearance
    ├── images.nss            Icon definitions
    ├── modify.nss            Modify default context menu entries
    ├── file-manage.nss       Copy path, attributes, take ownership
    ├── develop.nss           Developer tools (VSCode, Git, etc.)
    ├── goto.nss              Go-to shortcuts (system dirs, shell folders)
    ├── terminal.nss          Terminal profiles (disabled by default)
    └── taskbar.nss           Taskbar context menu entries
```

`*` = customized, tracked in `local/`

## Setup

Place customized `.nss` files in `local/` and symlink them into the install directory on Windows.
