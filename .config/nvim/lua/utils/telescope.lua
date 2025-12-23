-- Telescope utility functions
local M = {}

function M.smart_grep()
  local conf = require('telescope.config').values
  local finders = require 'telescope.finders'
  local make_entry = require 'telescope.make_entry'
  local pickers = require 'telescope.pickers'

  local function parse_input(prompt)
    -- Split by 2+ consecutive spaces into exactly 2 parts: search term and path filter
    local first_split = prompt:find '  '
    if not first_split then
      return vim.trim(prompt), nil
    end

    local search_term = vim.trim(prompt:sub(1, first_split - 1))
    local path_filter = vim.trim(prompt:sub(first_split + 2))

    return search_term, path_filter
  end

  local function parse_path_filter(path_filter)
    -- Returns: search_dir, glob_pattern
    -- - Path-like (.config/ or src/utils): use as directory
    -- - Glob-like (*.lua): use as --glob
    -- - Simple word (utils): use as --glob with wildcards
    if not path_filter or path_filter == '' then
      return nil, nil
    end

    -- Explicit glob pattern
    if path_filter:match '%*' then
      return nil, path_filter
    end

    -- Path-like: contains / or starts with .
    if path_filter:match '/' or path_filter:match '^%.' then
      local dir = path_filter:gsub('/$', '')
      return dir, nil
    end

    -- Simple word: match paths containing it
    return nil, '**/' .. path_filter .. '/**'
  end

  local live_grepper = finders.new_job(function(prompt)
    if not prompt or prompt == '' then
      return nil
    end

    local search_term, path_filter = parse_input(prompt)

    if search_term == '' then
      return nil
    end

    local args = {}

    for _, arg in ipairs(conf.vimgrep_arguments) do
      table.insert(args, arg)
    end

    local search_dir, glob_pattern = parse_path_filter(path_filter)

    if glob_pattern then
      table.insert(args, '--glob')
      table.insert(args, glob_pattern)
    end

    table.insert(args, '--')
    table.insert(args, search_term)

    if search_dir then
      table.insert(args, search_dir)
    end

    return args
  end, make_entry.gen_from_vimgrep {}, nil, nil)

  pickers
    .new({}, {
      prompt_title = 'Smart Grep (search  path)',
      finder = live_grepper,
      previewer = conf.grep_previewer {},
      sorter = require('telescope.sorters').empty(),
    })
    :find()
end

return M
