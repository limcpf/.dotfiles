" Markdown / 한국어 편집. 원래 설정은 snapshots/initial-home/에 보관합니다.
set nocompatible
set encoding=utf-8
let mapleader = ' '
let maplocalleader = ' '
let s:ubuntu_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h')
let s:vim_home = get(g:, 'dotfiles_vim_home', expand('~/.vim'))
execute 'set runtimepath^=' . fnameescape(s:vim_home)

" vim-plug 후처리에서 최초 환경의 npm lockfile로 의존성을 재현합니다.
function! DotfilesBuildMarkdownPreview(info) abort
  let l:app = g:plugs['markdown-preview.nvim'].dir . '/app'
  let l:lock = s:ubuntu_root . '/locks/markdown-preview-package-lock.json'
  if !executable('npm') || !filereadable(l:lock)
    throw 'Markdown 미리보기: npm 또는 dotfiles의 lockfile이 없습니다.'
  endif
  call writefile(readfile(l:lock), l:app . '/package-lock.json')
  let l:output = system('cd ' . shellescape(l:app) . ' && npm ci --omit=dev --no-fund')
  if v:shell_error
    throw 'Markdown 미리보기 의존성 설치 실패: ' . l:output
  endif
endfunction

if filereadable(s:vim_home . '/autoload/plug.vim')
  call plug#begin(s:vim_home . '/plugged')
  Plug 'preservim/vim-markdown', { 'commit': '1bc9d0cd8e1cc3e901b0a49c2b50a843f1c89397' }
  Plug 'godlygeek/tabular', { 'commit': '12437cd1b53488e24936ec4b091c9324cafee311' }
  Plug 'iamcco/markdown-preview.nvim', { 'commit': 'a923f5fc5ba36a3b17e289dc35dc17f66d0548ee', 'do': function('DotfilesBuildMarkdownPreview') }
  call plug#end()
endif

filetype plugin indent on
syntax enable
set fileencoding=utf-8
set fileencodings=utf-8,euc-kr,cp949,latin1
" 터미널과 기호 폭이 어긋나면 :set ambiwidth=single 로 비교하세요.
set ambiwidth=double
set emoji
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
let &showbreak = '↳ '
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

let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 0
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_new_list_item_indent = 0
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_autowrite = 1
let g:mkdp_auto_start = 0
let g:mkdp_auto_close = 1
let g:mkdp_refresh_slow = 0

augroup markdown_setup
  autocmd!
  " cjk는 한글을 오탈자로 표시하지 않도록 합니다. 한국어 맞춤법 검사는 아닙니다.
  " 별도 맞춤법 사전이 설치되지 않은 환경에서는 경고를 내지 않습니다.
  autocmd FileType markdown setlocal nospell wrap linebreak conceallevel=0
  autocmd FileType markdown nnoremap <buffer> <localleader>p :MarkdownPreview<CR>
  " 기존 쉼표 2회 → 。 입력 매핑도 그대로 보존합니다.
  autocmd FileType markdown inoremap <buffer> ,, <Esc>A。<Esc>
augroup END

nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>h :nohlsearch<CR>

if filereadable(expand('~/.vimrc.local'))
  source ~/.vimrc.local
endif
