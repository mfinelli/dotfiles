set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

let g:blamer_enabled = 1
let g:blamer_relative_time = 1

" https://vi.stackexchange.com/a/30774
set guicursor=i:block

" https://stackoverflow.com/a/75665834
lua require('init')
