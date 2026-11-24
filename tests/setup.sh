#!/bin/sh
set -eu

sandbox=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
trap 'rm -rf "$sandbox"' EXIT
export HOME="$sandbox/home with spaces"
unset ZSH_CUSTOM
mkdir -p "$HOME" "$sandbox/bin"
DOTFILES_TEST_GIT=$(command -v git)
export DOTFILES_TEST_GIT
export PATH="$sandbox/bin:$PATH"

cat >"$sandbox/bin/git" <<'EOF'
#!/bin/sh
set -eu
if [ "$1" = config ]; then
    exec "$DOTFILES_TEST_GIT" "$@"
fi
[ "$1 $2 $3" = 'clone --depth 1' ]
case "$4" in
    */ohmyzsh.git) file=oh-my-zsh.sh ;;
    */alias-tips.git) file=alias-tips.plugin.zsh ;;
    */zsh-syntax-highlighting.git) file=zsh-syntax-highlighting.plugin.zsh ;;
    *) exit 1 ;;
esac
[ ! -e "$5" ]
mkdir -p "$5"
touch "$5/$file"
EOF

cat >"$sandbox/bin/curl" <<'EOF'
#!/bin/sh
set -eu
[ "$1 $2" = '-fsSL -o' ]
[ "$4" = https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim ]
cat >"$3" <<'VIM'
function! plug#begin(...) abort
  let g:plugs = {'fixture': {'dir': expand('~/.vim/plugged/fixture')}}
  command! -nargs=+ Plug echo ''
  command! -nargs=1 PlugInstall call s:install(<q-args>)
endfunction
function! plug#end() abort
endfunction
function! s:install(args) abort
  call writefile([a:args], expand('~/.plug-install'))
  if $FAIL_PLUGIN !=# '1'
    call mkdir(g:plugs.fixture.dir, 'p')
  endif
endfunction
VIM
[ "${FAIL_DOWNLOAD:-0}" = 0 ]
EOF
chmod +x "$sandbox/bin/git" "$sandbox/bin/curl"

printf 'existing config\n' >"$HOME/.zshrc"
if make setup >"$sandbox/output" 2>&1; then
    printf 'Expected setup to reject an existing config.\n' >&2
    exit 1
fi
[ "$(cat "$HOME/.zshrc")" = 'existing config' ]
[ ! -e "$HOME/.oh-my-zsh" ]
rm "$HOME/.zshrc"

printf '[user]\n\temail = untouched@example.com\n' >"$sandbox/foreign-config"
ln -s "$sandbox/foreign-config" "$HOME/.gitconfig"
if make setup >"$sandbox/output" 2>&1; then
    printf 'Expected setup to reject a foreign Git config symlink.\n' >&2
    exit 1
fi
[ "$(readlink "$HOME/.gitconfig")" = "$sandbox/foreign-config" ]
[ ! -e "$HOME/.oh-my-zsh" ]
rm "$HOME/.gitconfig"

if FAIL_DOWNLOAD=1 make setup >"$sandbox/output" 2>&1; then
    printf 'Expected setup to fail when vim-plug could not be downloaded.\n' >&2
    exit 1
fi
[ ! -e "$HOME/.vim/autoload/plug.vim" ]
[ ! -L "$HOME/.zshrc" ]

if FAIL_PLUGIN=1 make setup >"$sandbox/output" 2>&1; then
    printf 'Expected setup to fail when a Vim plugin is missing.\n' >&2
    exit 1
fi
grep -Fq 'Missing Vim plugins: fixture' "$sandbox/output"
[ ! -L "$HOME/.zshrc" ]

make setup
repo=$(pwd -P)
for file in .aliases .tmux.conf .vimrc .zshrc; do
    [ "$(readlink "$HOME/$file")" = "$repo/$file" ]
done
[ ! -L "$HOME/.gitconfig" ]
[ "$(git config --global --no-includes --get-all include.path)" = "$repo/.gitconfig" ]
[ "$(git config --global --includes --get alias.g)" = 'grep -n' ]
[ "$(cat "$HOME/.plug-install")" = --sync ]

rm "$HOME/.gitconfig"
ln -s "$repo/.gitconfig" "$HOME/.gitconfig"
make setup
[ ! -L "$HOME/.gitconfig" ]
[ "$(git config --global --no-includes --get-all include.path)" = "$repo/.gitconfig" ]

cat >"$sandbox/local-config" <<'EOF'
# Settings specific to this machine
[user]
    email = local@example.com
[alias]
    g = status --short
EOF
cp "$sandbox/local-config" "$HOME/.gitconfig"
printf 'concurrent update\n' >"$HOME/.gitconfig.lock"
if make setup >"$sandbox/output" 2>&1; then
    printf 'Expected setup to reject a concurrent Git config update.\n' >&2
    exit 1
fi
cmp "$sandbox/local-config" "$HOME/.gitconfig"
[ "$(cat "$HOME/.gitconfig.lock")" = 'concurrent update' ]
rm "$HOME/.gitconfig.lock"

make setup
[ "$(git config --global --includes --get user.email)" = local@example.com ]
[ "$(git config --global --includes --get alias.g)" = 'status --short' ]
tail -n +4 "$HOME/.gitconfig" >"$sandbox/preserved-config"
cmp "$sandbox/local-config" "$sandbox/preserved-config"
git config --global user.email updated@example.com
cp "$HOME/.gitconfig" "$sandbox/first-run-config"
output=$(FAIL_DOWNLOAD=1 ./install.sh 2>&1)
[ "$output" = 'Installing Vim plugins...' ]
cmp "$HOME/.gitconfig" "$sandbox/first-run-config"
[ "$(git config --global --includes --get user.email)" = updated@example.com ]
zsh -n "$HOME/.zshrc"
