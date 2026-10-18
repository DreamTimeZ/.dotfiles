# Local Zsh Modules

Every `*.zsh` file here is sourced last (by `config/local.zsh`), so it can override any export, alias, function, or keybinding. All of them are git-ignored. They are symlinked from `~/.dotfiles-private`, except `api-keys.zsh`, which `api-keys-setup` generates here. `example.zsh.template` shows common overrides. On macOS, store API keys with `api-keys-setup` ([API keys](../../../../docs/api-keys-security.md)), not as plain exports here.
