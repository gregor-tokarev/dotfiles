return {
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        opts = {
            ensure_installed = { "lua", "markdown", "markdown_inline", "astro", "typescript", "vue", "zig", "rust", "go" },
            auto_install = true
        }
    },
}
