#!/bin/sh
set -eu

sandbox=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
trap 'rm -rf "$sandbox"' EXIT
export HOME="$sandbox/home with spaces"
unset ZSH_CUSTOM
mkdir -p "$HOME" "$sandbox/bin"
export PATH="$sandbox/bin:$PATH"

cat >"$sandbox/bin/git" <<'EOF'
#!/bin/sh
set -eu
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
for file in .aliases .gitconfig .tmux.conf .vimrc .zshrc; do
    [ "$(readlink "$HOME/$file")" = "$repo/$file" ]
done
[ "$(cat "$HOME/.plug-install")" = --sync ]
output=$(FAIL_DOWNLOAD=1 ./install.sh 2>&1)
[ "$output" = 'Installing Vim plugins...' ]
zsh -n "$HOME/.zshrc"
