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
    -- Install only parsers you actually use
    ensure_installed = {
        "lua", "vim", "vimdoc", "query", "regex",  -- Nvim essentials
        "bash", "fish",  -- Shells (zsh not available in treesitter)
        "python", "javascript", "typescript", "java", "c", "cpp", "go", "rust",  -- Common languages
        "json", "yaml", "toml", "xml", "ini",  -- Config formats
        "markdown", "markdown_inline", "comment",  -- Documentation
        "git_config", "git_rebase", "gitcommit", "gitignore", "diff",  -- Git
        "html", "css", "scss", "dockerfile",  -- Web/DevOps
        "sql", "graphql",  -- Query languages
        "make", "cmake"  -- Build tools
    },
    -- Auto-install parsers when opening new file types
    auto_install = true,
    highlight = {
        enable = true,
        -- Disable for very large files (performance)
        disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
                return true
            end
        end,
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
