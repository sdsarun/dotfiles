set nocompatible	
set encoding=utf-8
"-------------- run code -----------------"
autocmd filetype c nnoremap <F9> :w <bar> !gcc % -o %:r<CR>
autocmd filetype c nnoremap <F10> :!./%:r <CR>

autocmd filetype cpp nnoremap <F9> :w <bar> !g++ -std=c++17 % -o %:r<CR>
"autocmd filetype cpp nnoremap <F9> :w <bar> !g++ % -o %:r<CR>
autocmd filetype cpp nnoremap <F10> :!./%:r <CR>

autocmd filetype java nnoremap <F10> :w <bar> !java % <CR>

autocmd FileType python nnoremap <buffer> <F10> :w<CR>:exec '!python3' shellescape(@%, 1)<CR>
" autocmd FileType python imap <buffer> <F10> <esc>:w<CR>:exec '!python3' shellescape(@%, 1)<CR>
"-------------- Plugin -------------------- 
call plug#begin()

Plug 'preservim/nerdtree'
Plug 'mattn/emmet-vim'

" Unmanaged plugin (manually installed and updated)
Plug '~/my-prototype-plugin'

" Initialize plugin system
" - Automatically executes `filetype plugin indent on` and `syntax enable`.
call plug#end()

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
