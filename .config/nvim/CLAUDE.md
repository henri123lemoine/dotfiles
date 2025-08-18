# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is a Neovim configuration based on kickstart.nvim with custom plugins and personal modifications. The configuration is designed for a comprehensive development environment with LSP support, modern editing features, and integrated tools.

## Architecture

**Plugin Management**: Uses lazy.nvim for plugin management with lazy loading. Main configuration is in `init.lua:182` with plugins loaded from:
- Core plugins: Directly in `init.lua` 
- Kickstart plugins: `lua/kickstart/plugins/` (optional modules like autopairs, neo-tree, gitsigns)
- Custom plugins: `lua/custom/plugins/` (personal additions imported at `init.lua:950`)

**Configuration Structure**: 
- `init.lua` - Main configuration file with options, keymaps, autocommands, and core plugin setup
- `lazy-lock.json` - Lockfile for plugin versions
- `lua/custom/plugins/` - Personal plugin configurations (harpoon, lazygit, markdown tools, bufferline, etc.)
- `lua/kickstart/` - Optional kickstart modules

**LSP Configuration**: Configured with mason.nvim for automatic server installation. Supports clangd, gopls, rust_analyzer, pyright, ruff, lua_ls, and typescript-language-server with automatic installation via mason-tool-installer.

## Key Features & Plugins

**Core Tools**:
- Telescope (fuzzy finder) - `init.lua:284`
- LSP with mason auto-install - `init.lua:405` 
- Treesitter with context - `init.lua:846`
- nvim-cmp for autocompletion - `init.lua:671`
- which-key for keybind discovery - `init.lua:222`

**Custom Additions**:
- Harpoon2 for file navigation - `lua/custom/plugins/harpoon.lua`
- LazyGit integration - `lua/custom/plugins/lazygit.lua`
- Bufferline for tab-like buffer display - `lua/custom/plugins/init.lua:58`
- Claude Code integration - `lua/custom/plugins/init.lua:137`
- Markdown preview and rendering - `lua/custom/plugins/init.lua:4`

## Development Workflow

The configuration is optimized for multi-language development with automatic LSP setup, formatting on save, and comprehensive search capabilities. The Material theme provides consistent theming with WezTerm terminal.

