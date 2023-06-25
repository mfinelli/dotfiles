require'nvim-treesitter.configs'.setup {
    -- A list of parser names, or "all". The documentation says that
    -- "c", "lua", "vim", "vimdoc", and "query" must always be installed.
    -- https://github.com/nvim-treesitter/nvim-treesitter#supported-languages
    ensure_installed = {
        "c", "lua", "query", "vim", "vimdoc", "awk", "bash", "comment", "css",
        "diff", "dockerfile", "embedded_template", "git_config", "git_rebase",
        "gitattributes", "gitcommit", "gitignore", "go", "gomod", "gosum",
        "hcl", "html", "http", "ini", "javascript", "jq", "json", "latex",
        "make", "markdown", "markdown_inline", "passwd", "pug", "python",
        "regex", "ruby", "rust", "scss", "sql", "svelte", "terraform", "toml",
        "typescript", "yaml"
    },
    auto_install = true,
    highlight = {enable = true}
}
