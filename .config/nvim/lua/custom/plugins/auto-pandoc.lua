-- auto-pandoc.nvim
return {
  'jghauser/auto-pandoc.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  ft = 'markdown',
  config = function()
    local auto_pandoc = require 'auto-pandoc'
    local Job = require 'plenary.job'

    local server_job
    local browser_sync_job

    -- Helper function to run shell commands
    local function run_command(cmd)
      local output = vim.fn.system(cmd)
      if vim.v.shell_error ~= 0 then
        vim.notify('Error: ' .. output, vim.log.levels.ERROR)
      else
        vim.notify('Success: ' .. cmd, vim.log.levels.INFO)
      end
    end

    -- Function to generate PDF
    local function generate_pdf()
      local input = vim.fn.shellescape(vim.fn.expand '%:p')
      local output = vim.fn.shellescape(vim.fn.expand '%:p:r' .. '.pdf')
      run_command(string.format('pandoc %s -o %s --pdf-engine=xelatex', input, output))
    end

    -- Function to generate HTML with MathJax support
    local function generate_html()
      local input = vim.fn.shellescape(vim.fn.expand '%:p')
      local output = vim.fn.shellescape(vim.fn.expand '%:p:r' .. '.html')
      local mathjax_url = vim.fn.shellescape 'https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.7/MathJax.js?config=TeX-AMS_CHTML-full'
      local title = vim.fn.shellescape(vim.fn.expand '%:t:r')
      run_command(string.format('pandoc %s -o %s --mathjax=%s --standalone --metadata title=%s', input, output, mathjax_url, title))
      -- Trigger browser-sync reload
      vim.fn.system 'browser-sync reload --port 3000'
    end

    -- Function to generate both PDF and HTML
    local function generate_both()
      generate_pdf()
      generate_html()
    end

    -- Function to start local server and browser-sync
    local function start_preview_server()
      local current_dir = vim.fn.expand '%:p:h'

      server_job = Job:new {
        command = 'python',
        args = { '-m', 'http.server', '8000' },
        cwd = current_dir,
      }
      server_job:start()

      browser_sync_job = Job:new {
        command = 'browser-sync',
        args = { 'start', '--proxy', 'localhost:8000', '--files', '*.html', '--port', '3000' },
        cwd = current_dir,
      }
      browser_sync_job:start()

      vim.notify('Preview server started. Open http://localhost:3000 in your browser.', vim.log.levels.INFO)
    end

    -- Function to stop preview server
    local function stop_preview_server()
      if server_job then
        server_job:shutdown()
      end
      if browser_sync_job then
        browser_sync_job:shutdown()
      end
      vim.notify('Preview server stopped.', vim.log.levels.INFO)
    end

    -- Set up keymaps for markdown files
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      callback = function()
        vim.keymap.set('n', 'go', auto_pandoc.run_pandoc, { buffer = true, desc = 'Run auto-pandoc' }) -- uses YAML frontmatter
        vim.keymap.set('n', 'gp', generate_pdf, { buffer = true, desc = 'Generate PDF' })
        vim.keymap.set('n', 'gh', generate_html, { buffer = true, desc = 'Generate HTML' })
        vim.keymap.set('n', 'gb', generate_both, { buffer = true, desc = 'Generate PDF and HTML' })
        vim.keymap.set('n', 'gs', start_preview_server, { buffer = true, desc = 'Start preview server' })
        vim.keymap.set('n', 'gS', stop_preview_server, { buffer = true, desc = 'Stop preview server' })
      end,
    })

    -- Stop preview server when Neovim exits
    vim.api.nvim_create_autocmd('VimLeavePre', {
      callback = stop_preview_server,
    })
  end,
}
