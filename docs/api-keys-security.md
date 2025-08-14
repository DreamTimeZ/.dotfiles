# API Keys Security

Stores ChatGPT, Gemini, and Claude API keys in macOS Keychain. Keys auto-load as environment variables on shell start.

## How It Works

1. **Storage**: Keys encrypted in macOS Keychain (`dotfiles-api-keys` service)
2. **Loading**: `~/.dotfiles/zsh/config/modules/local/api-keys.zsh` retrieves keys on shell start
3. **Export**: Available as environment variables on shell start `$OPENAI_API_KEY`, `$GEMINI_API_KEY`, `$CLAUDE_API_KEY`
4. **Security**: No plaintext keys in dotfiles, git-ignored config

## Setup

```zsh
cd ~/.dotfiles
./bin/api-keys-setup
source ~/.zshrc
```

Get API keys from:

- **OpenAI**: [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
- **Gemini**: [makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)  
- **Claude**: [console.anthropic.com/account/keys](https://console.anthropic.com/account/keys)

## Commands

```zsh
api_keys_status           # Check stored keys
api_key_remove openai     # Remove specific key
./bin/api-keys-setup      # Update/add keys
```
