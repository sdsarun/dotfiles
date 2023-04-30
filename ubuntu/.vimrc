set nocompatible	
set encoding=utf-8
"-------------- run code -----------------"
"autocmd BufRead,BufNewFile *.htm,*.html setlocal tabstop=2 shiftwidth=2 softtabstop=2

autocmd filetype c nnoremap <F9> :w <bar> !gcc % -o %:r<CR>
autocmd filetype c nnoremap <F10> :!./%:r <CR>

autocmd filetype cpp nnoremap <F9> :w <bar> !g++ -std=c++17 % -o %:r<CR>
"autocmd filetype cpp nnoremap <F9> :w <bar> !g++ % -o %:r<CR>
autocmd filetype cpp nnoremap <F10> :!./%:r <CR>

autocmd filetype java nnoremap <F10> :w <bar> !java % <CR>

autocmd FileType python nnoremap <buffer> <F10> :w<CR>:exec '!python3' shellescape(@%, 1)<CR>
" autocmd FileType python imap <buffer> <F10> <esc>:w<CR>:exec '!python3' shellescape(@%, 1)<CR>
"-------------- Plugin -------------------- 
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'


" my packages.
Plugin 'scrooloose/nerdtree'
"Plugin 'alvan/vim-closetag'
"Plugin 'mattn/emmet-vim'

call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

"-------------line number-----------------"
set number relativenumber
"set cursorline
set number
"-------------insert tabwidth-------------" 
set showcmd
set ruler
set showmatch
set wildmenu
"------------ Searching-------------------"
set incsearch
set hlsearch
"-------------indentation--------------"
set smartindent
set autoindent
set smarttab
set tabstop=4
set shiftwidth=4
"------------Theme-------------------"
syntax on
"set termguicolors
set background=dark
"set background=light
"set t_Co=256
"highlight Comment ctermfg=cyan
"--------------Vim no Sound -------------"
set visualbell
"------------ No Delay -----------------"
set ttimeout
set ttimeoutlen=100
set timeoutlen=3000
"----------- remap key ----------------"
nmap <F1> :NERDTreeToggle<CR>
