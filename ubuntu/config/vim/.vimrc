" Markdown and Korean-friendly Vim setup
set nocompatible
filetype off

call plug#begin('~/.vim/plugged')
Plug 'preservim/vim-markdown'
Plug 'godlygeek/tabular'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm install' }
call plug#end()

filetype plugin indent on
syntax enable

" Korean/Unicode text
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,euc-kr,cp949,latin1
set ambiwidth=double
set emoji

" Comfortable editing
set number
set relativenumber
set cursorline
" 현재 행은 밑줄 없이 은은한 배경색으로만 강조합니다.
highlight CursorLine cterm=NONE ctermbg=234 guibg=#1c1c1c
highlight CursorLineNr cterm=bold ctermfg=117 ctermbg=234 guifg=#87d7ff guibg=#1c1c1c
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent
set smartindent
set wrap
set linebreak
set breakindent
set showbreak=↳\ 
set formatoptions+=jcroql
set backspace=indent,eol,start
set wildmenu
set incsearch
" 검색 중에는 강조하지만 검색이 끝난 뒤에는 남겨두지 않습니다.
set nohlsearch
set ignorecase
set smartcase
set hidden
set mouse=a
" 맞춤법 사전이 없는 환경에서 단어를 색칠하지 않습니다.
set nospell

" 터미널 Vim에서도 모드별 커서 모양을 명확히 표시합니다.
set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50

" 검색을 끝내면 검색어 강조를 자동으로 지웁니다.
augroup search_cleanup
  autocmd!
  autocmd CmdlineLeave /,\? nohlsearch
augroup END

" Markdown defaults
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 0
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_autowrite = 1
let g:mkdp_auto_start = 0
let g:mkdp_auto_close = 1
let g:mkdp_refresh_slow = 0

" Markdown-only conveniences
augroup markdown_setup
  autocmd!
  " 별도 맞춤법 사전이 설치되지 않은 환경에서는 경고를 내지 않습니다.
  autocmd FileType markdown setlocal nospell wrap linebreak
  autocmd FileType markdown setlocal conceallevel=0
  autocmd FileType markdown nnoremap <buffer> <localleader>p :MarkdownPreview<CR>
  autocmd FileType markdown inoremap <buffer> ,, <Esc>A。<Esc>
augroup END

" <leader> is backslash by default
let mapleader = " "
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>h :nohlsearch<CR>
