# config

# Install
```
git clone https://github.com/sdsarun/dotfiles.git ~/.dotverse
```
```
git clone git@github.com:sdsarun/dotfiles.git ~/.dotverse
```
## Symlink
To create a symlink
```
ln -s [Source_File_Path] [Symbolic_Link_Path]
// or
ln -s [Source_Directory_Path] [Symbolic_Link_Destination_Path]
```

## Install picker
Run the installer to choose configurations interactively:
```
./install.sh
```

Use arrows or `j/k` to navigate, space to toggle, `a` for all/none, `m` to
switch between install and unlink mode, Enter to confirm, and `q` to cancel.
Unlink mode only removes symlinks that point to the expected file in this
repository; foreign symlinks and regular files are preserved.

For scripted cleanup, use:
```
./install.sh --unlink --yes
```

# CLI Packages
- lazygit
- lazydocker
- bat
- bpytop
- exa
- duf
- httpie
- tre
- gping
- dua-cli
