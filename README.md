# dotfiles

This repository contains dotfiles and a transactional setup script to provision a new macOS environment safely.

The key guarantee: a successful run means everything was set up; a failed run leaves your system unchanged (best-effort for Homebrew packages). No partial state.

Requires git and Homebrew on MacOS.

## What the setup does

- Symlinks any top-level hidden files/dirs in this repo (e.g., `.zshenv`) into `$HOME`, and links subdirectories in `.config/` (e.g., `.config/git/`, `.config/zsh/`, `.config/nvim/`) to `$HOME/.config/`.
- Optionally clones external configs (instead of submodules) as declared in `external_repos.txt`. If a destination already exists and is a git repo whose `origin` matches the manifest's URL, it is reused instead of failing.
- Includes a `dotfiles-private/` submodule for sensitive/personal configurations that are kept separate from the main public repository.

Transactional behavior and safety:

- Full preflight: The script scans your `$HOME` for conflicts before making any change. If conflicts are found, it prints a clear report (with diffs for changed files) and exits without modifying anything.
- All-or-nothing: After preflight passes, the script tracks every mutation:
  - Symlinks created are removed on failure.
  - Directories created for external clones are removed on failure.
  - If `$HOME/.config` did not exist and is created for linking, it is removed on failure (only if the script created it and it is empty).
  - Homebrew packages installed during the run are uninstalled on failure (best-effort; incidental dependencies may remain).
- Handled errors don’t trigger rollback mid-run: the script only rolls back when it actually exits with a non-zero status.

## Usage

```sh
git clone https://github.com/henri123lemoine/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup
```

Environment flags:

- `SETUP_RELINK_IDENTICAL=1` replaces identical pre-existing files in `$HOME` with symlinks to this repo (so future edits in the repo propagate). Example:

  ```sh
  SETUP_RELINK_IDENTICAL=1 ./setup
  ```

## External repos

Declare repositories to be cloned during setup using `external_repos.txt` at the repo root. Each non-empty, non-comment line has the form:

```bash
relative/path|git_url|optional_branch
```

Example:

```bash
.config/alacritty|https://github.com/someone/alacritty-config.git|
```

## Credits

Thanks to [Fraser Ross Lee's dotfiles](https://github.com/FraserLee/dotfiles), which was the inspiration for much for this and from which some of this config was shamelessly copied.
