# dotfiles

This repository contains dotfiles and a transactional setup script to provision a new macOS environment safely.

The key guarantee: a successful run means everything was set up; a failed run leaves your system unchanged (best-effort for Homebrew packages). No partial state.

## What the setup does

- Symlinks any top-level hidden files/dirs in this repo (e.g., `.zshrc`, `.gitconfig`) into `$HOME`.
- Honors Git ignore rules: any repo entries matched by `.gitignore` are skipped and will not be symlinked.
- Optionally clones external configs (instead of submodules) as declared in `external_repos.txt`. If a destination already exists and is a git repo whose `origin` matches the manifest’s URL, it is reused instead of failing.

## Transactional behavior and safety

- Full preflight: The script scans your `$HOME` for conflicts before making any change. If conflicts are found, it prints a clear report (with diffs for changed files) and exits without modifying anything.
- All-or-nothing: After preflight passes, the script tracks every mutation:
  - Symlinks created are removed on failure.
  - Directories created for external clones are removed on failure.
  - If `$HOME/.config` did not exist and is created for linking, it is removed on failure (only if the script created it and it is empty).
  - Homebrew packages installed during the run are uninstalled on failure (best-effort; incidental dependencies may remain).
- Handled errors don’t trigger rollback mid-run: the script only rolls back when it actually exits with a non-zero status.

## Requirements

- macOS with Homebrew installed (for package installation). If you don’t plan to install packages, Homebrew is not required.
- `git` for cloning external repositories.

## Usage

```sh
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
cd ~/dotfiles
# optional: edit external_repos.txt and Brewfile
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

Examples:

```bash
.config/nvim|https://github.com/henri123lemoine/nvim.git|main
.config/alacritty|https://github.com/someone/alacritty-config.git|
```

Behavior:

- If the destination already exists, it’s reported as a conflict and the script aborts.

## Package installs with Homebrew

### Brewfile + brew bundle

- Add a `Brewfile` to the repo root and the setup will run `brew bundle install --no-upgrade --file Brewfile`.
- This declaratively ensures the target state (installs or no-ops if already installed). See the official docs: [Homebrew Bundle, brew bundle and Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile).
- On failure, the setup script will best-effort uninstall any formulae/casks that were newly installed during the bundle run to approximate transactional behavior.

## Notes and limitations

- Homebrew uninstall is best-effort: some automatically-installed dependencies may remain. The script still ensures that your dotfiles and cloned directories are rolled back completely on failure.
- The script never overwrites your existing files or directories; it aborts with a clear report instead.
- Existing symlinks that already point to the repo are treated as already-correct and won’t block.

## Global .gitignore behavior

- This repo uses a single `.gitignore` file to serve both as the repository ignore and your global Git ignore.
- The setup links `.gitignore` to `$HOME/.gitignore` and ensures `git config --global core.excludesfile "$HOME/.gitignore"` is set so Git uses it globally.

## Credits

Thanks to [Fraser Ross Lee's dotfiles](https://github.com/FraserLee/dotfiles), from which much of this config is shamelessly copied.
