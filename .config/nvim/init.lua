-- Global settings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = false
vim.g.ts_highlight_lua = false

-- Core options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Core keymaps
-- Essential navigation
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation (vim-tmux-navigator)
vim.keymap.set('n', '<C-h>', '<cmd>TmuxNavigateLeft<cr>', { desc = 'Navigate left (tmux-aware)' })
vim.keymap.set('n', '<C-l>', '<cmd>TmuxNavigateRight<cr>', { desc = 'Navigate right (tmux-aware)' })
vim.keymap.set('n', '<C-j>', '<cmd>TmuxNavigateDown<cr>', { desc = 'Navigate down (tmux-aware)' })
vim.keymap.set('n', '<C-k>', '<cmd>TmuxNavigateUp<cr>', { desc = 'Navigate up (tmux-aware)' })

-- Enhanced navigation
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Half page down and center' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Half page up and center' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next search result and center' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous search result and center' })

-- Buffer management
vim.keymap.set('n', '<Tab>', ':bnext<CR>', { desc = 'Next buffer', silent = true })
vim.keymap.set('n', '<S-Tab>', ':bprev<CR>', { desc = 'Previous buffer', silent = true })
vim.keymap.set('n', '<leader>bd', ':bdelete<CR>', { desc = 'Delete buffer', silent = true })
vim.keymap.set('n', '<leader>ba', ':%bd|e#<CR>', { desc = 'Delete all buffers except current', silent = true })

-- Tab management
vim.keymap.set('n', '<leader>tn', ':tabnew<CR>', { desc = 'New tab', silent = true })
vim.keymap.set('n', '<leader>tc', ':tabclose<CR>', { desc = 'Close tab', silent = true })
vim.keymap.set('n', '<leader>to', ':tabonly<CR>', { desc = 'Close all other tabs', silent = true })
for i = 1, 5 do
  vim.keymap.set('n', '<A-' .. i .. '>', i .. 'gt', { desc = 'Go to tab ' .. i, silent = true })
end

-- Utilities
vim.keymap.set('n', '<leader>ya', ':%y+<CR>', { desc = 'Copy entire file' })
vim.keymap.set('n', '<leader>+', '<C-a>', { desc = 'Increment number' })
vim.keymap.set('n', '<leader>-', '<C-x>', { desc = 'Decrement number' })
vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Toggle file explorer', silent = true })
vim.keymap.set('n', '<leader>?', ':e ~/.config/nvim/doc/help.md<CR>', { desc = 'Open help cheatsheet', silent = true })

-- Diagnostics
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix list' })

-- Folding
vim.keymap.set('n', 'zR', 'zR', { desc = 'Open all folds' })
vim.keymap.set('n', 'zM', 'zM', { desc = 'Close all folds' })
vim.keymap.set('n', 'za', 'za', { desc = 'Toggle fold under cursor' })
vim.keymap.set('n', 'zo', 'zo', { desc = 'Open fold under cursor' })
vim.keymap.set('n', 'zc', 'zc', { desc = 'Close fold under cursor' })

-- Arrow key reminders
local arrow_msg = function(key)
  return '<cmd>echo "Use ' .. key .. ' to move!!"<CR>'
end
vim.keymap.set('n', '<left>', arrow_msg 'h')
vim.keymap.set('n', '<right>', arrow_msg 'l')
vim.keymap.set('n', '<up>', arrow_msg 'k')
vim.keymap.set('n', '<down>', arrow_msg 'j')
vim.keymap.set('i', '<left>', '<cmd>echo "Use normal mode and h to move!!"<CR>')
vim.keymap.set('i', '<right>', '<cmd>echo "Use normal mode and l to move!!"<CR>')
vim.keymap.set('i', '<up>', '<cmd>echo "Use normal mode and k to move!!"<CR>')
vim.keymap.set('i', '<down>', '<cmd>echo "Use normal mode and j to move!!"<CR>')

-- Autocommands
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Treesitter folding (files open fully expanded due to foldlevel=99)
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'lua', 'python', 'javascript', 'typescript', 'json', 'yaml' },
  group = vim.api.nvim_create_augroup('treesitter-folding', { clear = true }),
  callback = function()
    if vim.treesitter.get_parser then
      vim.opt_local.foldmethod = 'expr'
      vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    end
  end,
})

-- Install lazy.nvim
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Plugin setup
require('lazy').setup({
  'tpope/vim-sleuth',
  'ThePrimeagen/vim-be-good',
  'christoomey/vim-tmux-navigator',

  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Next git change' })

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Previous git change' })

        map('v', '<leader>hs', function()
          gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'Stage git hunk' })
        map('v', '<leader>hr', function()
          gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'Reset git hunk' })
        map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Git stage hunk' })
        map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Git reset hunk' })
        map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'Git stage buffer' })
        map('n', '<leader>hu', gitsigns.undo_stage_hunk, { desc = 'Git undo stage hunk' })
        map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'Git reset buffer' })
        map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'Git preview hunk' })
        map('n', '<leader>hb', gitsigns.blame_line, { desc = 'Git blame line' })
        map('n', '<leader>hd', gitsigns.diffthis, { desc = 'Git diff against index' })
        map('n', '<leader>hD', function()
          gitsigns.diffthis '@'
        end, { desc = 'Git diff against last commit' })
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle git blame line' })
        map('n', '<leader>tD', gitsigns.toggle_deleted, { desc = 'Toggle git show deleted' })
      end,
    },
  },

  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          BS = '<BS> ',
        },
      },
      spec = {
        { '<leader>c', group = '[C]ode', mode = { 'n', 'x' } },
        { '<leader>d', group = '[D]ocument' },
        { '<leader>r', group = '[R]ename' },
        { '<leader>s', group = '[S]earch' },
        { '<leader>w', group = '[W]orkspace' },
        { '<leader>t', group = '[T]abs/Toggle' },
        { '<leader>b', group = '[B]uffers' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
        { '<leader>g', group = '[G]it' },
      },
    },
  },

  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        extensions = {
          ['ui-select'] = { require('telescope.themes').get_dropdown() },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Find existing buffers' })
      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
      end, { desc = 'Search in current buffer' })
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
      end, { desc = '[S]earch in open files' })
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
      vim.keymap.set('n', '<leader>rs/', function()
        local root = string.gsub(vim.fn.system 'git rev-parse --show-toplevel', '\n', '')
        if vim.v.shell_error == 0 then
          builtin.live_grep { cwd = root }
        else
          builtin.live_grep()
        end
      end, { desc = 'Search in git root' })
    end,
  },

  { 'folke/lazydev.nvim', ft = 'lua', opts = { library = { { path = 'luvit-meta/library', words = { 'vim%.uv' } } } } },
  { 'Bilal2453/luvit-meta', lazy = true },

  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'hrsh7th/cmp-nvim-lsp',
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          local builtin = require 'telescope.builtin'
          map('gd', builtin.lsp_definitions, 'Goto Definition')
          map('gr', builtin.lsp_references, 'Goto References')
          map('gI', builtin.lsp_implementations, 'Goto Implementation')
          map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
          map('<leader>D', builtin.lsp_type_definitions, 'Type Definition')
          map('<leader>ds', builtin.lsp_document_symbols, 'Document Symbols')
          map('<leader>ws', builtin.lsp_dynamic_workspace_symbols, 'Workspace Symbols')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action', { 'n', 'x' })

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, 'Toggle Inlay Hints')
          end
        end,
      })
      local capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), require('cmp_nvim_lsp').default_capabilities())

      local servers = {
        clangd = {},
        gopls = {},
        rust_analyzer = {},
        pyright = { settings = { python = { venvPath = '.', venv = '.venv' } } },
        ruff = {},
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
              diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      require('mason').setup()

      local ensure_installed = vim.tbl_keys(servers)
      vim.list_extend(ensure_installed, { 'stylua', 'typescript-language-server' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },

  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        desc = 'Format buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        return {
          timeout_ms = 500,
          lsp_format = disable_filetypes[vim.bo[bufnr].filetype] and 'never' or 'fallback',
        }
      end,
      formatters_by_ft = { lua = { 'stylua' } },
    },
  },

  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        build = (vim.fn.has 'win32' == 0 and vim.fn.executable 'make' == 1) and 'make install_jsregexp' or nil,
      },
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        preselect = cmp.PreselectMode.None,
        completion = { completeopt = 'menu,menuone,noinsert,noselect' },
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete {},
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),
        },
        sources = {
          { name = 'lazydev', group_index = 0 },
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
        },
      }
    end,
  },

  {
    'marko-cerovac/material.nvim',
    priority = 1000,
    init = function()
      vim.g.material_style = 'darker'
      vim.cmd.colorscheme 'material'
      vim.cmd.hi 'Comment gui=none'
      vim.cmd.hi 'Comment guifg=#9E9E9E'
    end,
  },

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
      require('mini.comment').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    dependencies = { 'nvim-treesitter/nvim-treesitter-context' },
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'python' },
      auto_install = true,
      highlight = { enable = true, additional_vim_regex_highlighting = { 'ruby' } },
      indent = { enable = true, disable = { 'ruby' } },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = { ['af'] = '@function.outer', ['if'] = '@function.inner' },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { [']m'] = '@function.outer' },
          goto_next_end = { [']M'] = '@function.outer' },
          goto_previous_start = { ['[m'] = '@function.outer' },
          goto_previous_end = { ['[M'] = '@function.outer' },
        },
      },
    },
    config = function(_, opts)
      require('nvim-treesitter.configs').setup(opts)
      require('treesitter-context').setup {
        enable = true,
        max_lines = 0,
        line_numbers = true,
        multiline_threshold = 20,
        trim_scope = 'outer',
        mode = 'cursor',
        zindex = 20,
      }
    end,
  },

  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    dependencies = { 'hrsh7th/nvim-cmp' },
    config = function()
      require('nvim-autopairs').setup {}
      local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
      local cmp = require 'cmp'
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },

  {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons', 'MunifTanjim/nui.nvim' },
    cmd = 'Neotree',
    keys = { { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true } },
    opts = {
      filesystem = {
        window = { mappings = { ['\\'] = 'close_window' } },
        filtered_items = {
          visible = true,
          show_hidden_count = true,
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = { '.git', '.DS_Store' },
          never_show = {},
        },
      },
    },
  },

  -- Custom plugins
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup()
      vim.keymap.set('n', '<m-h><m-m>', function()
        harpoon:list():add()
      end)
      vim.keymap.set('n', '<m-h><m-l>', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)
      for i = 1, 5 do
        vim.keymap.set('n', '<space>' .. i, function()
          harpoon:list():select(i)
        end)
      end
    end,
  },

  { 'kdheepak/lazygit.nvim', dependencies = { 'nvim-lua/plenary.nvim' }, keys = { { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'LazyGit' } } },


  {
    'MeanderingProgrammer/markdown.nvim',
    name = 'render-markdown',
    ft = { 'markdown' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = { enabled = true, max_file_size = 5.0, render_modes = { 'n', 'c' } },
  },

  {
    'iamcco/markdown-preview.nvim',
    ft = { 'markdown' },
    build = function(plugin)
      if vim.fn.executable 'npx' then
        vim.cmd('!cd ' .. plugin.dir .. ' && cd app && npx --yes yarn install')
      else
        vim.fn['mkdp#util#install']()
      end
    end,
  },

  {
    'jghauser/auto-pandoc.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    ft = 'markdown',
    config = function()
      local auto_pandoc = require 'auto-pandoc'
      local function generate_pdf()
        local input = vim.fn.shellescape(vim.fn.expand '%:p')
        local output = vim.fn.shellescape(vim.fn.expand '%:p:r' .. '.pdf')
        vim.fn.system(string.format('pandoc %s -o %s --pdf-engine=xelatex', input, output))
        vim.notify(vim.v.shell_error == 0 and 'PDF generated' or 'PDF generation failed', vim.log.levels.INFO)
      end
      local function generate_html()
        local input = vim.fn.shellescape(vim.fn.expand '%:p')
        local output = vim.fn.shellescape(vim.fn.expand '%:p:r' .. '.html')
        vim.fn.system(string.format('pandoc %s -o %s --mathjax --standalone', input, output))
        vim.notify(vim.v.shell_error == 0 and 'HTML generated' or 'HTML generation failed', vim.log.levels.INFO)
      end
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        callback = function()
          vim.keymap.set('n', 'go', auto_pandoc.run_pandoc, { buffer = true, desc = 'Run auto-pandoc' })
          vim.keymap.set('n', 'gp', generate_pdf, { buffer = true, desc = 'Generate PDF' })
          vim.keymap.set('n', 'gh', generate_html, { buffer = true, desc = 'Generate HTML' })
          vim.keymap.set('n', 'gb', function()
            generate_pdf()
            generate_html()
          end, { buffer = true, desc = 'Generate PDF and HTML' })
        end,
      })
    end,
  },

  {
    'akinsho/bufferline.nvim',
    dependencies = 'nvim-tree/nvim-web-devicons',
    opts = {
      options = {
        mode = 'buffers',
        themable = true,
        diagnostics = 'nvim_lsp',
        separator_style = 'slant',
        always_show_bufferline = true,
        close_command = 'bdelete! %d',
        right_mouse_command = 'bdelete! %d',
      },
    },
  },

  { 'kevinhwang91/nvim-bqf', ft = 'qf', opts = { auto_enable = true } },

}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
