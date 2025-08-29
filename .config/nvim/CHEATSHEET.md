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
- `<C-h/j/k/l>` - Move between window splits

### File & Buffer Management

- `<Space>e` - Toggle file explorer (Neotree)
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
- `<Space>sd` - Search diagnostics
- `<Space>s.` - Search recent files
- `<Space>/` - Search in current buffer
- `<Space>s/` - Search in open files
- `<Space>sn` - Search in Neovim config
- `<Space>rs/` - Search in git project root

### Harpoon (Quick File Access)

- `<Alt-h><Alt-m>` - Add file to harpoon
- `<Alt-h><Alt-l>` - Toggle harpoon menu
- `<Space>1/2/3/4/5` - Jump to harpoon file 1/2/3/4/5

### Git Integration

- `<Space>lg` - Open LazyGit

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

### Diagnostics

- `[d` / `]d` - Previous/next diagnostic
- `<Space>e` - Show diagnostic error message
- `<Space>q` - Open diagnostic quickfix list

### Editing & Text Manipulation

- `<Space>ya` - Copy entire file
- `<Space>+` / `<Space>-` - Increment/decrement number
- `<Esc>` - Clear search highlights

### Claude Code Integration

- `<Space>ac` - Toggle Claude Code
- `<Space>af` - Focus Claude Code
- `<Space>ar` - Resume Claude Code session
- `<Space>aC` - Continue Claude Code
- `<Space>am` - Select Claude model
- `<Space>ab` - Add current buffer to Claude
- `<Space>as` - Send selection to Claude (visual mode)
- `<Space>aa` - Accept Claude diff
- `<Space>ad` - Deny Claude diff

### Markdown

- `go` - Run auto-pandoc
- `gp` - Generate PDF
- `gh` - Generate HTML
- `gb` - Generate both PDF and HTML
- `gs` - Start preview server
- `gS` - Stop preview server

