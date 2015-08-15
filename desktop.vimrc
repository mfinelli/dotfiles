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

" other plugins
Plug 'tpope/vim-sensible'

if exists("s:bootstrap") && s:bootstrap
    unlet s:bootstrap
    autocmd VimEnter * PlugInstall
endif

call plug#end()

" The caveat is that you should *never* use PlugUpgrade
delc PlugUpgrade

" :W sudo saves the file
command W w !sudo tee % > /dev/null

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
