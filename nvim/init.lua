-- 🛠 Plugin Manager (lazy.nvim) setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
                   lazypath})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({{
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate"
}, -- 🌳 Syntax highlighting
{"nvim-lualine/lualine.nvim"}, -- 📊 Status line
{
    "nvim-telescope/telescope.nvim",
    dependencies = {"nvim-lua/plenary.nvim"}
}, -- 🔭 Fuzzy finder
{"tpope/vim-commentary"}, -- 📝 Quick commenting
{"nvim-tree/nvim-tree.lua"}, -- 📂 File explorer
{"lewis6991/gitsigns.nvim"} -- 🟢 Git signs
})

-- 🌈 Enable Treesitter Syntax Highlighting
require("nvim-treesitter.configs").setup {
    ensure_installed = "all",
    highlight = {
        enable = true
    }
}

-- 🖱 Enable Mouse Support
vim.opt.mouse = "a"

-- 📋 Clipboard Integration (macOS)
vim.opt.clipboard = "unnamedplus" -- Uses system clipboard

-- 🏎 Faster Rendering
vim.opt.lazyredraw = true
vim.opt.updatetime = 250

-- 🚀 Optimized UI
vim.opt.termguicolors = true
vim.cmd([[ colorscheme desert ]])

-- 🔍 Better Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- 📂 File Explorer Keybinding
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", {
    noremap = true,
    silent = true
})

-- 🏎 Speed Up Navigation
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.wrap = false
