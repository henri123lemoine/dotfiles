# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

Single-file configuration in `init.lua` using lazy.nvim. Space leader key with mnemonic prefixes. Mason.nvim handles LSP servers (clangd, gopls, rust_analyzer, pyright, ruff, lua_ls, typescript-language-server).

## Key Plugins

- **Telescope**: Fuzzy finding and search
- **LSP + Mason**: Auto-installing language servers
- **Treesitter**: Syntax highlighting and text objects
- **Git**: gitsigns + vim-fugitive
- **Harpoon**: Quick file navigation (Space + 1-5)
- **Completion**: nvim-cmp with LSP and snippets
- **Formatting**: conform.nvim (format-on-save, disabled for C/C++)

