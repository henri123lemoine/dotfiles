# Help

Neovim commands reminders / cheatsheet / etc.

## In Normal Mode

*Leader key is `<Space>` - most custom commands start with space*
`<Space>?` - Open help cheatsheet

### Movement

- `hjkl` - Basic movement
- `<C-d>` / `<C-u>` - Half page down/up
- `n` / `N` - Next/previous search result
- `<C-h/j/k/l>` - Pane navigation

### File & Buffer Management

- `<Tab>` / `<S-Tab>` - Next/previous buffer
- `<Space><Space>` - Find existing buffers
- `<Space>bd` - Delete current buffer
- `<Space>ba` - Delete all buffers except current

### Search & Find

- `<Space>sf` - Search files
- `<Space>sg` - Search by grep (live)
- `<Space>sw` - Search current word
- `<Space>sh` - Search help
- `<Space>sk` - Search keymaps
- `<Space>ss` - Search select telescope
- `<Space>sd` - Search diagnostics
- `<Space>sr` - Search resume
- `<Space>s.` - Search recent files
- `<Space>/` - Search in current buffer
- `<Space>s/` - Search in open files
- `<Space>sn` - Search in Neovim config
- `<Space>rs/` - Search in git root

### Harpoon

- `<Space-ha>` - Add file to harpoon
- `<Space-hm>` - Toggle harpoon menu
- `<Space>1/2/3/4/5` - Jump to harpoon file 1/2/3/4/5

### Git Integration (Gitsigns)

- `]c` / `[c` - Next/previous git change
- `<Space>hs` - Stage hunk
- `<Space>hr` - Reset hunk
- `<Space>hS` - Stage buffer
- `<Space>hR` - Reset buffer
- `<Space>hp` - Preview hunk
- `<Space>hb` - Blame line
- `<Space>hd` - Diff against index
- `<Space>hD` - Diff against last commit
- `<Space>tb` - Toggle git blame line
- `<Space>tD` - Toggle git show deleted

### LSP & Code Actions

- `gd` - Go to definition
- `gr` - Go to references
- `gI` - Go to implementation
- `gD` - Go to declaration
- `<Space>D` - Type definition
- `<Space>rn` - Rename symbol
- `<Space>ca` - Code action
- `<Space>ds` - Document symbols
- `<Space>ws` - Workspace symbols
- `<Space>f` - Format buffer
- `<Space>th` - Toggle inlay hints

### Diagnostics

- `[d` / `]d` - Previous/next diagnostic
- `<Space>q` - Open diagnostic quickfix list

## In Insert Mode

- `<C-y>` / `<C-e>`: inserts the character above / below
- `<C-w>` / `<C-h>` / `<C-u>`: deletes the word / character/ line before the cursor
- `<C-o>`: one shot mode: lets you do one normal mode command and then return to insert
- `<C-t>` / `<C-d>`: tab and untab your current line
- `<C-j>` / `<C-k>`: move down / up (i'm not sure about this one, doesn't seem to work for me)
- `<C-a>`: reinserts the last text (though this is also my tmux prefix)
- `<C-r>`: inserts the content of a register
- `<C-n>` / `<C-p>` - Select next/previous item

