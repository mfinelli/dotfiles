" vim-plug bootstrap: https://github.com/jwhitley/vimrc
" some set options: https://github.com/amix/vimrc/blob/master/vimrcs/basic.vim

set nocompatible
set encoding=utf-8
scriptencoding utf-8

let g:vimrc_home=expand("<sfile>:h")
function! Dot_vim(path)
    return g:vimrc_home."/.vim/".a:path
endfunction

let s:bundle_home=Dot_vim("bundle")
let s:plug_tool_home=Dot_vim("bundle/vim-plug")

if !isdirectory(Dot_vim("bundle/vim-plug/.git"))
    silent exec "!mkdir -p ".s:bundle_home
    silent exec "!git clone --depth 1 https://github.com/jwhitley/vim-plug.git ".s:plug_tool_home
    let s:bootstrap=1
endif

exec "set rtp+=".s:plug_tool_home
call plug#begin(s:bundle_home)

" let vim-plug manage vim-plug
Plug 'jwhitley/vim-plug'

" Colors
Plug 'fxn/vim-monochrome'
Plug '29decibel/codeschool-vim-theme'
Plug 'xero/sourcerer.vim'
Plug 'tomasr/molokai'
Plug 'nanotech/jellybeans.vim'
Plug 'sjl/badwolf'

" Generic plugins
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-flagship'
Plug 'tpope/vim-ragtag'
Plug 'tpope/vim-tbone'
Plug 'tpope/vim-haystack'
Plug 'tpope/vim-characterize'
Plug 'scrooloose/nerdtree' | Plug 'jistr/vim-nerdtree-tabs'
Plug 'Yggdroot/indentLine'

" Git plugins
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" Ruby plugins
Plug 'tpope/vim-projectionist' | Plug 'tpope/vim-rake'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-endwise'

" JSON
Plug 'elzr/vim-json'

if exists("s:bootstrap") && s:bootstrap
    unlet s:bootstrap
    autocmd VimEnter * PlugInstall
endif

call plug#end()

" The caveat is that you should *never* use PlugUpgrade
delc PlugUpgrade

" Be smart about case when searching
set smartcase

" Show matching brackets
set showmatch

" How many tenths of a second to blink when matching brackets
set mat=2

" Use Unix as the standard file type
set ffs=unix,dos,mac

" Use spaces instead of tabs
set expandtab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

" use two spaces for ruby files
autocmd FileType ruby setlocal shiftwidth=2 tabstop=2

" Wrap lines
set wrap

" Treat long lines as break lines
map j gj
map k gk

" Delete trailing whitespace on save
func! DeleteTrailingWS()
    exe "normal mz"
    %s/\s\+$//ge
    exe "normal `z"
endfunc
autocmd BufWrite *.py :call DeleteTrailingWS()
autocmd BufWrite *.coffee :call DeleteTrailingWS()

" Highlight the 80th column
if (exists('+colorcolumn'))
    set colorcolumn=80
    highlight ColorColumn ctermbg=9
endif

" Force *.md files to markdown instead of modula-2
autocmd BufNewFile,BufReadPost *.md set filetype=markdown

" Show line numbers
set number

" Startup nerdtree automatically
" autocmd vimenter * NERDTree

" Startup nerdtree if no files are specified
" autocmd StdinReadPre * let s:std_in=1
" autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Close vim if the only window left open is nerdtree
" autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

let g:nerdtree_tabs_open_on_console_startup=1

" Turn off JSON concealing
let g:vim_json_syntax_conceal = 0

" Set the colorscheme
set background=dark
try
    colorscheme monochrome
catch
endtry