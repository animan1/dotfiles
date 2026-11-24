#!/bin/sh
set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
dotfiles='.aliases .gitconfig .tmux.conf .vimrc .zshrc'

for file in $dotfiles; do
    dest="$HOME/$file"
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$repo/$file" ]; then
        continue
    fi
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        printf 'Move %s aside and rerun make setup.\n' "$dest" >&2
        exit 1
    fi
done

for tool in git curl vim zsh; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Install %s and rerun make setup.\n' "$tool" >&2
        exit 1
    fi
done

clone_if_missing() {
    if [ ! -f "$2/$3" ]; then
        git clone --depth 1 "$1" "$2"
    fi
}

zsh_dir="$HOME/.oh-my-zsh"
zsh_plugins="${ZSH_CUSTOM:-$zsh_dir/custom}/plugins"
clone_if_missing https://github.com/ohmyzsh/ohmyzsh.git "$zsh_dir" oh-my-zsh.sh
clone_if_missing https://github.com/djui/alias-tips.git \
    "$zsh_plugins/alias-tips" alias-tips.plugin.zsh
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$zsh_plugins/zsh-syntax-highlighting" zsh-syntax-highlighting.plugin.zsh

plug="$HOME/.vim/autoload/plug.vim"
if [ ! -s "$plug" ]; then
    mkdir -p "$(dirname -- "$plug")"
    download=$(mktemp "$plug.XXXXXX")
    trap 'rm -f "$download"' EXIT
    curl -fsSL -o "$download" https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    mv -f "$download" "$plug"
    trap - EXIT
fi

vim_log=$(mktemp "${TMPDIR:-/tmp}/dotfiles-vim.XXXXXX")
trap 'rm -f "$vim_log"' EXIT
printf '%s\n' 'Installing Vim plugins...'
if ! vim -N -u "$repo/.vimrc" -i NONE -n -es -V1 \
    '+PlugInstall --sync' \
    '+let missing = keys(filter(copy(g:plugs), "!isdirectory(v:val.dir)"))' \
    '+if !empty(missing) | echomsg "Missing Vim plugins: " . join(sort(missing), ", ") | cquit | endif' \
    '+qa!' </dev/null >"$vim_log" 2>&1; then
    printf '%s\n' 'Vim plugin installation failed.' >&2
    cat "$vim_log" >&2
    exit 1
fi

for file in $dotfiles; do
    dest="$HOME/$file"
    if [ ! -L "$dest" ]; then
        ln -s "$repo/$file" "$dest"
    fi
done
