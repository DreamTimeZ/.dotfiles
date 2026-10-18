# API Keys

`api-keys-setup` (macOS, linked into `~/.local/bin`) stores API keys in the macOS Keychain under the service `dotfiles-api-keys` and exports them as environment variables in every new shell. No key is written to disk in plaintext.

```zsh
api-keys-setup                 # interactive setup
api-keys-setup openai claude   # set specific services
api-keys-setup --status        # which keys are stored
api-keys-setup --list          # all supported services
api-keys-setup --remove openai
api-keys-setup --help
```

It generates `zsh/config/modules/local/api-keys.zsh` (git-ignored), which reads each key from the Keychain at shell start. A variable that is already set is left alone, so a key exported elsewhere shadows the Keychain. For the same reason a running shell keeps the old value: after a change, `unset` the variable and run `exec zsh`, or open a new terminal (new tmux panes inherit the old value from the tmux server). Variable names are fixed per service, for example `OPENAI_API_KEY`, `GEMINI_API_KEY`, and `CLAUDE_API_KEY` (not `ANTHROPIC_API_KEY`).
