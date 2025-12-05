# spotify_player Cheatsheet

Open: `prefix + m` (tmux)

## Playback
| Key | Action |
|-----|--------|
| `space` | Play/Pause |
| `n` | Next track |
| `p` | Previous track |
| `<` / `>` | Seek back/forward |
| `+` / `-` | Volume up/down |
| `_` | Mute toggle |
| `C-r` | Cycle repeat (off/track/context) |
| `C-s` | Toggle shuffle |
| `.` | Play random track |

## Navigation
| Key | Action |
|-----|--------|
| `j/k` or `↑/↓` | Move up/down |
| `g` / `G` | Jump to top/bottom |
| `C-d` / `C-u` | Half page down/up |
| `Enter` | Select/play item |
| `Esc` | Close popup/go back |
| `q` | Quit |
| `?` | Show all keybindings |

## Views & Search
| Key | Action |
|-----|--------|
| `/` | Search |
| `L` | Library |
| `B` | Browse |
| `Q` | Queue |
| `D` | Switch device |
| `O` | Open context (album/artist) |
| `a` | Show artist |
| `A` | Show album |
| `gp` | Go to playlists |
| `ga` | Go to albums |
| `gr` | Go to recently played |

## Actions
| Key | Action |
|-----|--------|
| `s` | Save/like track |
| `C-space` | Add to queue |
| `y` | Copy URL |
| `r` | Radio (start from track) |
| `f` | Follow artist/playlist |

## Playlists
| Key | Action |
|-----|--------|
| `N` | New playlist |
| `M` | Add track to playlist |
| `d` | Delete from playlist |

## CLI (outside TUI)
```bash
spotify_player playback play-pause
spotify_player playback next
spotify_player playback previous
spotify_player playback volume 50
```
