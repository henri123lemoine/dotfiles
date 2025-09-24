# Help

Neovim commands reminders / cheatsheet / etc.

## In Insert Mode

Ctrl+y / +e: inserts the character above / below
Ctrl+w / +h / +u: deletes the word / character/ line before the cursor
Ctrl+o: one shot mode: lets you do one normal mode command and then return to insert
Ctrl+t / +d: tab and untab your current line
Ctrl+j / +k: move down / up (i'm not sure about this one, doesn't seem to work for me)
Ctrl+a: reinserts the last text (though this is also my tmux prefix)
Ctrl+r: inserts the content of a register

## In Normal Mode

*Leader key is `<Space>` - most custom commands start with space*

### Movement & Navigation

- `hjkl` - Basic movement (left, down, up, right)
- `<C-d>` / `<C-u>` - Half page down/up (centered)
- `n` / `N` - Next/previous search result (centered)
- `<C-h/j/k/l>` - Tmux navigation (left/down/up/right)
- `<Esc><Esc>` - Exit terminal mode (in terminal)

### File & Buffer Management

- `<Space>e` - Oil project root explorer
- `\` - Oil floating view
- `<Space>-` - Oil parent directory
- `<Tab>` / `<S-Tab>` - Next/previous buffer
- `<Space><Space>` - Find existing buffers (Telescope)
- `<Space>bd` - Delete current buffer
- `<Space>ba` - Delete all buffers except current

### Tab Management

- `<Space>tn` - New tab
- `<Space>tc` - Close tab
- `<Space>to` - Close all other tabs
- `<Alt-1/2/3/4/5>` - Go to tab 1/2/3/4/5

### Search & Find (Telescope)

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

### Harpoon (Quick File Access)

- `<Alt-h><Alt-m>` - Add file to harpoon
- `<Alt-h><Alt-l>` - Toggle harpoon menu
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

### Editing & Text Manipulation

- `<Space>ya` - Copy entire file
- `<Esc>` - Clear search highlights
- `<Space>?` - Open help cheatsheet

### Completion (Insert Mode)

- `<C-n>` / `<C-p>` - Select next/previous item
- `<C-b>` / `<C-f>` - Scroll docs up/down
- `<C-Space>` - Complete
- `<Tab>` / `<S-Tab>` - Select next/previous in completion
- `<C-l>` / `<C-h>` - Jump forward/back in snippets


