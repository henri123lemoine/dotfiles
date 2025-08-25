return {
  {
    'github/copilot.vim',
    config = function()
      -- Disable inline completions and tab mapping; Supermaven does this
      vim.g.copilot_enabled = false
      vim.g.copilot_no_tab_map = true
    end,
  },

  {
    'CopilotC-Nvim/CopilotChat.nvim',
    branch = 'main',
    dependencies = {
      { 'github/copilot.vim' },
      { 'nvim-lua/plenary.nvim' },
    },
    build = 'make tiktoken',
    opts = {
      debug = true,
    },
    keys = {
      { '<leader>gc', '<cmd>CopilotChatToggle<cr>', desc = 'Toggle Copilot Chat' },
      { '<leader>ge', '<cmd>CopilotChatExplain<cr>', desc = 'Explain code', mode = { 'n', 'v' } },
      { '<leader>gr', '<cmd>CopilotChatReview<cr>', desc = 'Review code', mode = { 'n', 'v' } },
      { '<leader>gf', '<cmd>CopilotChatFix<cr>', desc = 'Fix code', mode = { 'n', 'v' } },
      { '<leader>go', '<cmd>CopilotChatOptimize<cr>', desc = 'Optimize code', mode = { 'n', 'v' } },
      { '<leader>gd', '<cmd>CopilotChatDocs<cr>', desc = 'Generate docs', mode = { 'n', 'v' } },
      { '<leader>gt', '<cmd>CopilotChatTests<cr>', desc = 'Generate tests', mode = { 'n', 'v' } },
    },
  },
}

