-- Global settings
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
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

-- Split border styling
vim.opt.fillchars = { vert = '│', horiz = '▀', horizup = '▀', horizdown = '▀', vertleft = '▌', vertright = '▌', verthoriz = '▌' }
vim.opt.laststatus = 3

-- Diagnostic configuration
vim.diagnostic.config {
  virtual_text = {
    spacing = 4,
    prefix = '●',
    format = function(diagnostic)
      local max_width = 100
      local message = diagnostic.message
      if #message > max_width then
        return message:sub(1, max_width) .. '...'
      end
      return message
    end,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = true,
    header = '',
    prefix = '',
    wrap = true,
    max_width = 80,
  },
}

vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

-- Core keymaps
-- Essential navigation
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation
vim.keymap.set('n', '<C-h>', '<cmd>TmuxNavigateLeft<cr>', { desc = 'Navigate left' })
vim.keymap.set('n', '<C-l>', '<cmd>TmuxNavigateRight<cr>', { desc = 'Navigate right' })
vim.keymap.set('n', '<C-j>', '<cmd>TmuxNavigateDown<cr>', { desc = 'Navigate down' })
vim.keymap.set('n', '<C-k>', '<cmd>TmuxNavigateUp<cr>', { desc = 'Navigate up' })

-- Enhanced navigation
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Half page down and center' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Half page up and center' })
vim.keymap.set('n', 'n', 'nzzzv', { desc = 'Next search result and center' })
vim.keymap.set('n', 'N', 'Nzzzv', { desc = 'Previous search result and center' })

-- Buffer management
vim.keymap.set('n', '<leader>bd', function()
  require('mini.bufremove').delete(0, false)
end, { desc = 'Delete buffer', silent = true })

-- Utilities
vim.keymap.set('n', '<leader>ya', ':%y+<CR>', { desc = 'Copy entire file' })
vim.keymap.set('n', '<leader>?', ':e ~/.config/nvim/CHEATSHEET.md<CR>', { desc = 'Open help cheatsheet', silent = true })

-- Diagnostics
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump { count = -1 }
end, { desc = 'Go to previous diagnostic' })
vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump { count = 1 }
end, { desc = 'Go to next diagnostic' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix list' })

-- Autocommands
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Treesitter folding
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
  'tpope/vim-repeat',
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
        vim.keymap.set('n', ']h', gitsigns.nav_hunk 'next', { buffer = bufnr, desc = 'Next git hunk' })
        vim.keymap.set('n', '[h', gitsigns.nav_hunk 'prev', { buffer = bufnr, desc = 'Previous git hunk' })
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
        { '<leader>t', group = '[T]oggle' },
        { '<leader>b', group = '[B]uffers' },
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
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Find existing buffers' })
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
      end, { desc = '[S]earch in open files' })
      vim.keymap.set('n', '<leader>rs/', function()
        local root = string.gsub(vim.fn.system 'git rev-parse --show-toplevel', '\n', '')
        if vim.v.shell_error == 0 then
          builtin.live_grep { cwd = root }
        else
          builtin.live_grep()
        end
      end, { desc = 'Search in git root' })

      -- Smart grep: parse "search-term  directory/  *.glob" in live prompt
      vim.keymap.set('n', '<leader>sG', function()
        require('utils.telescope').smart_grep()
      end, { desc = '[S]mart [G]rep (term  dir/  *.glob)' })
    end,
  },

  { 'folke/lazydev.nvim', ft = 'lua', opts = { library = { { path = 'luvit-meta/library', words = { 'vim%.uv' } } } } },
  { 'Bilal2453/luvit-meta', lazy = true },

  {
    'linux-cultist/venv-selector.nvim',
    ft = 'python',
    dependencies = { 'neovim/nvim-lspconfig' },
    opts = {},
    keys = {
      { '<leader>cv', '<cmd>VenvSelect<cr>', desc = 'Select VirtualEnv' },
    },
  },

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
          map('<leader>rn', vim.lsp.buf.rename, 'Rename')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action', { 'n', 'x' })

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
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

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, 'Toggle Inlay Hints')
          end
        end,
      })
      local capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), require('cmp_nvim_lsp').default_capabilities())

      capabilities.general = capabilities.general or {}
      capabilities.general.positionEncodings = { 'utf-8' }

      local servers = {
        clangd = {},
        gopls = {},
        rust_analyzer = {},
        pyright = {
          offset_encoding = 'utf-8',
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = 'workspace',
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
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
      vim.list_extend(ensure_installed, { 'stylua', 'typescript-language-server', 'ruff' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            server.capabilities.general = server.capabilities.general or {}
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
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'ruff_fix', 'ruff_format' },
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'BufReadPost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          require('lint').try_lint()
        end,
      })
    end,
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
      vim.api.nvim_set_hl(0, 'Comment', { fg = '#9E9E9E' })
      vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#ffffff', bg = 'NONE' })
    end,
  },

  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  {
    'mbbill/undotree',
    cmd = 'UndotreeToggle',
    keys = {
      { '<leader>u', '<cmd>UndotreeToggle<cr>', desc = 'Toggle undotree' },
    },
    config = function()
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_WindowLayout = 2
    end,
  },

  {
    'debugloop/telescope-undo.nvim',
    dependencies = {
      {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
    },
    keys = {
      { '<leader>su', '<cmd>Telescope undo<cr>', desc = '[S]earch [U]ndo history' },
    },
    config = function()
      require('telescope').load_extension 'undo'
      require('telescope').setup {
        extensions = {
          undo = {},
        },
      }
    end,
  },

  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
      require('mini.comment').setup()
      require('mini.bufremove').setup()
      require('mini.operators').setup {
        evaluate = { prefix = 'g=' },
        exchange = { prefix = 'gx' },
        multiply = { prefix = 'gm' },
        replace = { prefix = 'gr' },
      }
      require('mini.bracketed').setup()
    end,
  },

  {
    'tpope/vim-fugitive',
    cmd = { 'Git', 'Gstatus', 'Gblame', 'Gpush', 'Gpull' },
    keys = {
      { '<leader>gs', '<cmd>Git<cr>', desc = 'Git status' },
      { '<leader>gb', '<cmd>Git blame<cr>', desc = 'Git blame' },
      { '<leader>gd', '<cmd>Gvdiffsplit<cr>', desc = 'Git diff split' },
      { '<leader>gl', '<cmd>Git log --oneline<cr>', desc = 'Git log' },
    },
  },

  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        theme = 'auto',
        globalstatus = true,
        component_separators = { left = '│', right = '│' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = { statusline = { 'lazy', 'oil' }, winbar = {} },
      },
      sections = {
        lualine_a = {
          {
            'mode',
            icon = '',
            fmt = function(str)
              return str:sub(1, 1)
            end,
          },
        },
        lualine_b = { 'branch', 'diagnostics' },
        lualine_c = {
          { 'filename', path = 1, symbols = { modified = ' ●', readonly = ' ', unnamed = '[No Name]' } },
          { 'diff', symbols = { added = ' ', modified = ' ', removed = ' ' } },
        },
        lualine_x = { 'lsp_status', 'searchcount', 'selectioncount', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {},
      },
      extensions = { 'quickfix', 'lazy', 'fugitive' },
    },
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
        -- Note: text object selection (af/if) handled by mini.ai instead
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
        max_lines = 3,
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
    'mikavilpas/yazi.nvim',
    event = 'VeryLazy',
    keys = {
      { '-', '<cmd>Yazi<cr>', desc = 'Open yazi file manager' },
    },
    config = function()
      require('yazi').setup {
        open_for_directories = false,
        keymaps = {
          show_help = '<f1>',
        },
        yazi_floating_window_border = 'rounded',
        yazi_floating_window_winblend = 0,
      }
      vim.api.nvim_set_hl(0, 'YaziFloat', { bg = '#282a36' })
      vim.api.nvim_set_hl(0, 'YaziBorder', { fg = '#6272a4', bg = 'NONE' })
      vim.api.nvim_set_hl(0, 'FloatBorder', { fg = '#6272a4', bg = 'NONE' })
    end,
  },

  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup()
      vim.keymap.set('n', '<leader>ha', function()
        harpoon:list():add()
      end)
      vim.keymap.set('n', '<leader>hm', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)
      for i = 1, 5 do
        vim.keymap.set('n', '<space>' .. i, function()
          harpoon:list():select(i)
        end)
      end
    end,
  },

  {
    'MeanderingProgrammer/markdown.nvim',
    name = 'render-markdown',
    ft = { 'markdown' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = { enabled = true, max_file_size = 5.0, render_modes = { 'n', 'c' } },
  },

  {
    'vhyrro/luarocks.nvim',
    priority = 1001,
    opts = {
      rocks = { 'magick' },
    },
  },

  {
    '3rd/image.nvim',
    dependencies = { 'luarocks.nvim' },
    config = function()
      require('image').setup {
        backend = 'kitty',
        kitty_method = 'normal',
        processor = 'magick_rock',
        integrations = {
          markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            filetypes = { 'markdown', 'vimwiki' },
          },
          neorg = {
            enabled = true,
            filetypes = { 'norg' },
          },
          typst = {
            enabled = true,
            filetypes = { 'typst' },
          },
          html = {
            enabled = false,
          },
          css = {
            enabled = false,
          },
        },
        max_width = nil,
        max_height = nil,
        max_width_window_percentage = nil,
        max_height_window_percentage = 50,
        window_overlap_clear_enabled = false,
        window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
        editor_only_render_when_focused = false,
        tmux_show_only_in_active_window = false,
        hijack_file_patterns = { '*.png', '*.jpg', '*.jpeg', '*.gif', '*.webp', '*.avif' },
      }
    end,
  },

  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {},
    keys = {
      {
        'ss',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash jump',
      },
      {
        'S',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
      },
    },
  },
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
