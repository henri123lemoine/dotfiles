-- Telescope utility functions
local M = {}

function M.smart_grep()
  local conf = require('telescope.config').values
  local finders = require 'telescope.finders'
  local make_entry = require 'telescope.make_entry'
  local pickers = require 'telescope.pickers'

  local function parse_input(prompt)
    -- Split by 2+ consecutive spaces
    local split_parts = {}
    local current = ''
    local space_count = 0

    for i = 1, #prompt do
      local char = prompt:sub(i, i)
      if char == ' ' then
        space_count = space_count + 1
      else
        if space_count >= 2 and current ~= '' then
          table.insert(split_parts, current)
          current = char
        else
          current = current .. char
        end
        space_count = 0
      end
    end
    if current ~= '' then
      table.insert(split_parts, current)
    end

    local search_term = split_parts[1] or ''
    local dir = nil
    local glob_pattern = nil

    for i = 2, #split_parts do
      local part = vim.trim(split_parts[i])
      if part:match '/' or part:match '^%.' then
        dir = part
      elseif part ~= '' then
        glob_pattern = part
      end
    end

    return search_term, dir, glob_pattern
  end

  local live_grepper = finders.new_job(function(prompt)
    if not prompt or prompt == '' then
      return nil
    end

    local search_term, dir, glob_pattern = parse_input(prompt)

    if search_term == '' then
      return nil
    end

    local args = {}

    for _, arg in ipairs(conf.vimgrep_arguments) do
      table.insert(args, arg)
    end

    if glob_pattern then
      table.insert(args, '--glob')
      table.insert(args, glob_pattern)
    end

    table.insert(args, '--')
    table.insert(args, search_term)

    table.insert(args, dir or '.')

    return args
  end, make_entry.gen_from_vimgrep {}, nil, nil)

  pickers
    .new({}, {
      prompt_title = 'Smart Grep (term  [dir/]  [*.glob])',
      finder = live_grepper,
      previewer = conf.grep_previewer {},
      sorter = require('telescope.sorters').empty(),
    })
    :find()
end

return M
