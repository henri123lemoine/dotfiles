return {
  {
    'supermaven-inc/supermaven-nvim',
    event = 'InsertEnter',
    priority = 1000,
    config = function()
      require('supermaven-nvim').setup {
        keymaps = {
          accept_suggestion = '<Tab>',
          clear_suggestion = '<C-]>',
          accept_word = '<C-j>',
        },
        -- ignore_filetypes = { cpp = true },
        color = {
          suggestion_color = '#808080',
          cterm = 244,
        },
        log_level = 'info',
        disable_inline_completion = false,
        disable_keymaps = false,
      }
    end,
  },
}

