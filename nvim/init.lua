-- 🛠 Plugin Manager (lazy.nvim) setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
                   lazypath})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({{
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "lua", "vim", "vimdoc", "query", "regex",
                "bash", "fish",
                "python", "javascript", "typescript", "java", "c", "cpp", "go", "rust",
                "json", "yaml", "toml", "xml",
                "markdown", "markdown_inline", "comment",
                "git_config", "git_rebase", "gitcommit", "gitignore", "diff",
                "html", "css", "scss", "dockerfile",
                "sql", "graphql",
                "make", "cmake"
            },
            auto_install = true,
            highlight = {
                enable = true,
                disable = function(_, buf)
                    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                    return ok and stats and stats.size > 100 * 1024
                end,
            },
        })
    end,
},
{"nvim-lualine/lualine.nvim"},
{
    "nvim-telescope/telescope.nvim",
    dependencies = {"nvim-lua/plenary.nvim"}
},
{"tpope/vim-commentary"},
{"nvim-tree/nvim-tree.lua"},
{"lewis6991/gitsigns.nvim"}
})

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
