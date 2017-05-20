" some set options: https://github.com/amix/vimrc/blob/master/vimrcs/basic.vim

set nocompatible
set encoding=utf-8
scriptencoding utf-8

let g:vimrc_home=expand("<sfile>:h")
function! Dot_vim(path)
    return g:vimrc_home."/.vim/".a:path
endfunction

let s:bundle_home=Dot_vim("bundle")
call plug#begin(s:bundle_home)

" let vim-plug manage vim-plug
Plug 'junegunn/vim-plug'

" Colors
Plug 'fxn/vim-monochrome'
Plug '29decibel/codeschool-vim-theme'
Plug 'xero/sourcerer.vim'
Plug 'tomasr/molokai'
Plug 'nanotech/jellybeans.vim'
Plug 'sjl/badwolf'
Plug 'jacoborus/tender'
Plug 'jdkanani/vim-material-theme'

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
Plug 'tpope/vim-sleuth'
Plug 'tpope/vim-characterize'
Plug 'scrooloose/nerdtree' | Plug 'jistr/vim-nerdtree-tabs'
Plug 'Yggdroot/indentLine'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'vim-airline/vim-airline' | Plug 'vim-airline/vim-airline-themes'
Plug 'reedes/vim-pencil'
Plug 'jpalardy/vim-slime'

" Git plugins
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" Ruby plugins
Plug 'tpope/vim-projectionist' | Plug 'tpope/vim-rake'
Plug 'tpope/vim-bundler'
Plug 'tpope/vim-endwise'

" JSON
Plug 'elzr/vim-json'

" JavaScript
Plug 'digitaltoad/vim-pug'
Plug 'kchmck/vim-coffee-script'
Plug 'leafgarland/typescript-vim'

" other
Plug 'cometsong/ferm.vim'
Plug 'Matt-Deacalion/vim-systemd-syntax'
Plug 'hashivim/vim-terraform'

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

" use two spaces for ruby,javascript files
autocmd FileType ruby setlocal shiftwidth=2 tabstop=2
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
autocmd FileType coffee setlocal shiftwidth=2 tabstop=2
autocmd FileType pug setlocal shiftwidth=2 tabstop=2
autocmd FileType jade setlocal shiftwidth=2 tabstop=2
autocmd FileType yaml setlocal shiftwidth=2 tabstop=2

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
autocmd BufWrite *.yml :call DeleteTrailingWS()

" Highlight the 80th column
if (exists('+colorcolumn'))
    set colorcolumn=80
    highlight ColorColumn ctermbg=9
endif

" Force *.md files to markdown instead of modula-2
autocmd BufNewFile,BufReadPost *.md set filetype=markdown

" Show line numbers
set relativenumber

" Startup nerdtree automatically
" autocmd vimenter * NERDTree

" Startup nerdtree if no files are specified
" autocmd StdinReadPre * let s:std_in=1
" autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Close vim if the only window left open is nerdtree
" autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif

let g:nerdtree_tabs_open_on_console_startup=1
let g:NERDTreeShowHidden=1

" Turn off JSON concealing
let g:vim_json_syntax_conceal = 0

" config for vim-slime
let g:slime_target = "tmux"
" let g:slime_paste_file = tempname()

" Specific options for the jellybeans color scheme
let g:jellybeans_use_term_italics = 1
let g:jellybeans_use_lowcolor_black = 0
let g:jellybeans_overrides = {
            \'background': { 'ctermbg': 'none', '256ctermbg': 'none' },
            \}

" options for tender theme
" let g:tender_airline = 1
" let g:airline_theme = 'tender'

" Set the colorscheme
set background=dark
try
    colorscheme jellybeans
catch
endtry
