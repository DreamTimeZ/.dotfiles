-- Plugin Manager (lazy.nvim) setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
                   lazypath})
end
vim.opt.rtp:prepend(lazypath)

-- Must precede any mapping that uses <leader>
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- nvim-tree hijacks the netrw browser at runtime, which races with netrw's own
-- load; it must be disabled before any plugin is sourced.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local MAX_HIGHLIGHT_FILESIZE = 100 * 1024

local TS_PARSERS = {
    "lua", "vim", "vimdoc", "query", "regex",
    "bash", "fish",
    "python", "javascript", "typescript", "c", "cpp", "go", "rust",
    "json", "yaml", "toml", "xml",
    "markdown", "markdown_inline", "comment",
    "git_config", "git_rebase", "gitcommit", "gitignore", "diff",
    "html", "css", "scss", "dockerfile",
    "sql", "graphql",
    "make", "cmake"
}

-- Highlighting is Neovim-native. Neovim's own ftplugins (lua, markdown, help,
-- query) call vim.treesitter.start() unconditionally, so oversized buffers must
-- be stopped after those run rather than merely skipped here. start() throws for
-- a language with no parser, hence the pcall.
local function apply_highlight(buf)
    local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
    if stats and stats.size > MAX_HIGHLIGHT_FILESIZE then
        vim.schedule(function()
            pcall(vim.treesitter.stop, buf)
        end)
        return
    end
    pcall(vim.treesitter.start, buf)
end

require("lazy").setup({{
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false, -- upstream does not support lazy-loading: the filetype-to-parser
                  -- registrations live in the plugin's plugin/ directory
    build = ":TSUpdate",
    config = function()
        local treesitter = require("nvim-treesitter")
        treesitter.setup()
        -- No-op for parsers already present; on a first run it installs in the
        -- background, so re-apply highlighting to buffers opened meanwhile.
        -- Restarting a live highlighter would orphan it with its tree callbacks
        -- still registered, hence the ts_highlight check.
        treesitter.install(TS_PARSERS):await(vim.schedule_wrap(function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) and not vim.b[buf].ts_highlight then
                    apply_highlight(buf)
                end
            end
        end))
    end
}, {
    "nvim-lualine/lualine.nvim",
    config = function()
        require("lualine").setup()
    end
}, {
    "nvim-telescope/telescope.nvim",
    dependencies = {"nvim-lua/plenary.nvim"}
}, {"tpope/vim-commentary"}, {
    "nvim-tree/nvim-tree.lua",
    config = function()
        require("nvim-tree").setup()
    end
}, {"lewis6991/gitsigns.nvim"}})

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("treesitter_highlight", {clear = true}),
    callback = function(ev)
        apply_highlight(ev.buf)
    end
})

-- Enable Mouse Support
vim.opt.mouse = "a"

-- Clipboard Integration (macOS)
vim.opt.clipboard = "unnamedplus" -- Uses system clipboard

vim.opt.updatetime = 250

-- Optimized UI
vim.opt.termguicolors = true
vim.cmd([[ colorscheme desert ]])

-- Better Searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- File Explorer Keybinding
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", {
    noremap = true,
    silent = true
})

-- Speed Up Navigation
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.wrap = false
