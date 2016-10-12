" Allow vim to break compatibility with vi
set nocompatible " This must be first, because it changes other options

syntax on "Coloration and other pretty syntax

let mapleader=","

set number "Line numbers
set cursorline "highlight current line

set undofile "Create undo files to allow for undoes after closing a file

set t_Co=256
set hidden
set nowrap

"Tab key and indent related stuff
set ai "autoindent
set tabstop=4 "set tabs to 4 characters
set shiftwidth=4
set expandtab "Turns tabs to spaces
set softtabstop=4 "spaces feel like tabs

" Character meaning when present in 'formatoptions'
" ------ ---------------------------------------
" c Auto-wrap comments using textwidth, inserting the current comment leader automatically.
" q Allow formatting of comments with "gq".
" r Automatically insert the current comment leader after hitting <Enter> in Insert mode.
" t Auto-wrap text using textwidth (does not apply to comments)
" n Recognize numbered lists
" 1 Don't break line after one-letter words
" a Automatically format paragraphs
set formatoptions=cqn1
set textwidth=120

" When completing, fill with the longest common string
" Auto select the first option
set completeopt=longest,menuone

" Search stuff
set hlsearch "Highlight all search matches
set ignorecase "Make searches case insensitive
set smartcase "Don't ignore case if we have a capital letter
set incsearch "Show matches while typing the search string

set laststatus=2 "Keeps statusline on alllll the time

if exists('+colorcolumn')
    set colorcolumn=120        " Highlight the column after `textwidth`
endif

au BufWritePre * :%s/\s\+$//e  " clear white space in the end of lines

" show trailing whitespace
set list lcs=trail:·,precedes:«,extends:»,tab:▸\

set mouse=a " Allow scrolling with a mouse

" This is to deal with crappy iTerm mouse handling
if has("mouse_sgr")
    set ttymouse=sgr "This one makes mouse work past the 220th column
else
    set ttymouse=xterm2 "match iterm2 mouse settings
end

" Set splits to be more natural (down/right of current)
set splitbelow
set splitright

" Change wildmenu (tab completion menu) so that it works like the terminal
set wildmenu
set wildmode=list:longest

" Do not auto complete these files
set wildignore=*.o,*.pyc

set nostartofline

" Set colourscheme
colorscheme elflord

" Return to last edit position when opening files, except git commit message
" autocmd BufReadPost *
    \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal g`\"" |
    \ endif

" Bind <leader>y to forward last-yanked text to Clipper
nnoremap <leader>y :call system('nc localhost 8377', @0)<CR>

" Reselect visual block after indent/outdent: http://vimbits.com/bits/20
vnoremap < <gv
vnoremap > >gv
vnoremap = =gv

" <Ctrl-l> redraws the screen and removes any search highlighting.
nnoremap <silent> <C-l> :nohl<CR><C-l>

" Plugins

" List of plugins
call plug#begin('~/.vim/plugged')

Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'ctrlpvim/ctrlp.vim'
Plug 'Valloric/YouCompleteMe', { 'do': './install.py' }
autocmd! User YouCompleteMe if !has('vim_starting') | call youcompleteme#Enable() | endif
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'scrooloose/nerdcommenter'
Plug 'vim-scripts/YankRing.vim'
Plug 'vim-scripts/scratch.vim'
Plug 'kien/rainbow_parentheses.vim'
Plug 'tpope/vim-fugitive'
Plug 'vim-scripts/BufOnly.vim'
call plug#end()

" ==== Configuration for plugins ====
" ==== airline ====
" Move to the next buffer
nmap <leader>l :bnext<CR>

" Move to the previous buffer
nmap <leader>p :bprevious<CR>

" Close the current buffer and move to the previous one
" This replicates the idea of closing a tab
nmap <leader>w :bp <BAR> bd #<CR>

let g:airline#extensions#tabline#enabled = 1

" ==== CTRL-P ====
let g:ctrlp_working_path_mode = ''
let g:ctrlp_show_hidden = 1
let g:ctrlp_max_files = 30000
let g:ctrlp_custom_ignore = '\v\.(node_modules|DS_Store|git|virtualenvs?|pip_download_cache)$'

" If we have The Silver Searcher
if executable('ag')
    " Use ag over grep
    set grepprg=ag\ --nogroup\ --nocolor

    " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
    let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

    " ag is fast enough that CtrlP doesn't need to cache
    let g:ctrlp_use_caching = 0
endif

" ==== NERD Tree ====
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree
autocmd VimEnter * wincmd p

autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q
let NERDTreeIgnore = ['\.pyc$']
let NERDTreeShowHidden=1

" ==== Yank Ring ====
let g:yankring_paste_v_key = '<leader>v'
let g:yankring_replace_n_pkey = '<leader>['
let g:yankring_replace_n_nkey = '<leader>]'
