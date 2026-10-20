" Markdown 작성과 한국어 편집을 위한 Vim 설정
set nocompatible
filetype off

call plug#begin('~/.vim/plugged')
Plug 'preservim/vim-markdown'
Plug 'godlygeek/tabular'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm install' }
call plug#end()

filetype plugin indent on
syntax enable

" 한국어와 유니코드 텍스트
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,euc-kr,cp949,latin1
set ambiwidth=double
set emoji

" 편집 편의 설정
set number
set relativenumber
set cursorline
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent
set smartindent
set wrap
set linebreak
set breakindent
let &showbreak = '↳ '
set formatoptions+=jcroql
set backspace=indent,eol,start
set wildmenu
set incsearch
set hlsearch
set ignorecase
set smartcase
set hidden
set mouse=a

" Markdown 기본값
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 0
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_autowrite = 1
let g:mkdp_auto_start = 0
let g:mkdp_auto_close = 1
let g:mkdp_refresh_slow = 0

" Markdown 파일에서만 사용하는 편의 기능
augroup markdown_setup
  autocmd!
  autocmd FileType markdown setlocal spell spelllang=en_us,ko wrap linebreak
  autocmd FileType markdown setlocal conceallevel=0
  autocmd FileType markdown nnoremap <buffer> <localleader>p :MarkdownPreview<CR>
  autocmd FileType markdown inoremap <buffer> ,, <Esc>A。<Esc>
augroup END

" 기본 leader는 역슬래시이며 아래에서 공백으로 변경합니다.
let mapleader = " "
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>h :nohlsearch<CR>
