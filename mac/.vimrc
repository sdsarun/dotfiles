set nocompatible	
set encoding=UTF-8
"-------------- run code -----------------"
autocmd filetype c nnoremap <F9> :w <bar> !gcc % -o %:r<CR>
autocmd filetype c nnoremap <F10> :!./%:r <CR>
autocmd filetype cpp nnoremap <F9> :w <bar> !g++ -std=c++17 % -o %:r<CR>
"autocmd filetype cpp nnoremap <F9> :w <bar> !g++ % -o %:r<CR> autocmd filetype cpp nnoremap <F10> :!./%:r <CR>
autocmd filetype java nnoremap <F10> :w <bar> !java % <CR>
autocmd filetype javascript nnoremap <F10> :w <bar> !clear && node % <CR>

autocmd FileType python nnoremap <buffer> <F10> :w<CR>:exec '!python3' shellescape(@%, 1)<CR>
" autocmd FileType python imap <buffer> <F10> <esc>:w<CR>:exec '!python3' shellescape(@%, 1)<CR>
"-------------- Plugin -------------------- 
call plug#begin()

Plug 'preservim/nerdtree'
Plug 'mattn/emmet-vim'
Plug 'kien/ctrlp.vim'


Plug 'tpope/vim-surround'
Plug 'alvan/vim-closetag'
Plug 'sheerun/vim-polyglot'

" theme
Plug 'tomasiser/vim-code-dark' 

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
set nowrap
"------------Theme-------------------"
syntax on

"let g:molokai_original = 1
"let g:rehash256 = 1
"let g:dracula_italic = 0

"set termguicolors
set background=dark
"set background=light
"set t_Co=256


"color evening
"color koehler
"color slate
"color blue
color codedark

"colorscheme gruvbox
"colorscheme onedark

"highlight Comment ctermfg=lightgrey
"highlight LineNr ctermfg=grey

set fillchars=stl:^,stlnc:=,vert:\ ,fold:-,diff:-
highlight VertSplit guibg=Orange guifg=black ctermbg=6 ctermfg=0

"--------------Vim no Sound -------------"
set visualbell
"------------ No Delay -----------------"
set ttimeout
set ttimeoutlen=100
set timeoutlen=3000
"----------- remap key ----------------"
nmap <F1> :NERDTreeToggle<CR>
"----------- custome plugin settings ----------------"
let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.jsx'
let g:closetag_emptyTags_caseSensitive = 1

