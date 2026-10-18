# Neovim

Single-file Lua config (`init.lua`) with lazy.nvim and a committed `lazy-lock.json`. Plugins: nvim-treesitter, Telescope, nvim-tree, gitsigns, lualine, vim-commentary. Yank and paste use the system clipboard. `setup.sh` links both files into `~/.config/nvim/`.

## Requirements

- Neovim >= 0.12.0 (nvim-treesitter `main` supports stable and nightly only)
- `tree-sitter-cli` >= 0.26.1, from a package manager rather than npm (`brew install tree-sitter-cli`)
- A C compiler, plus `curl` and `tar`, for building parsers

## Notes

- nvim-treesitter loads eagerly, as upstream does not support lazy-loading. Highlighting is skipped for files above 100 KB.
- netrw is disabled, since nvim-tree replaces it and hijacking it at runtime races with netrw's own load. This removes `:Explore` and netrw's remote-editing handlers (`scp://`, `ftp://`). `gx` is unaffected, as Neovim implements it natively.
