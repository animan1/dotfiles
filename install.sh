#!/bin/sh
set -eu

repo=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
dotfiles='.aliases .tmux.conf .vimrc .zshrc'
git_config="$HOME/.gitconfig"
shared_git_config="$repo/.gitconfig"

check_git_config() {
    if [ -L "$git_config" ]; then
        [ "$(readlink "$git_config")" = "$shared_git_config" ] && return 0
    elif [ ! -e "$git_config" ] || [ -f "$git_config" ]; then
        return 0
    fi
    printf 'Move %s aside and rerun make setup.\n' "$git_config" >&2
    return 1
}

setup_git_config() (
    umask 077
    # Use the same lock as Git so setup cannot race a global config update.
    lock="$git_config.lock"
    if ! (set -C; : > "$lock") 2>/dev/null; then
        printf 'Could not lock %s. Check for another Git config update and rerun make setup.\n' "$git_config" >&2
        exit 1
    fi
    trap 'rm -f "$lock"' EXIT
    check_git_config

    existing=
    if [ ! -L "$git_config" ] && [ -f "$git_config" ]; then
        existing="$git_config"
        includes=$(git config --file "$existing" --no-includes --type=path --get-all include.path) || [ "$?" -eq 1 ]
        if printf '%s\n' "$includes" | grep -Fxq -- "$shared_git_config"; then
            exit 0
        fi
    fi

    git config --file "$lock" --add include.path "$shared_git_config"
    if [ -n "$existing" ]; then
        printf '\n' >> "$lock"
        cat "$existing" >> "$lock"
    fi
    git config --file "$lock" --no-includes --list >/dev/null
    mv -f "$lock" "$git_config"
    trap - EXIT
)

check_git_config

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

setup_git_config
for file in $dotfiles; do
    dest="$HOME/$file"
    if [ ! -L "$dest" ]; then
        ln -s "$repo/$file" "$dest"
    fi
done
