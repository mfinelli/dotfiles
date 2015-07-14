" Derived from: https://github.com/amix/vimrc/blob/master/vimrcs/basic.vim

" Sets how many lines of history to remember
set history=500

" Enable filetype plugin
filetype plugin on
filetype indent on

" Set to auto read when a file is changed externally
set autoread

" With a map leader it's possible to do extra key combinations
let mapleader = ","
let g:mapleader = ","

" :W sudo saves the file
command W w !sudo tee % > /dev/null

" Set seven lines to the cursor when moving vertically
set so=7

" Turn on wildmenu
set wildmenu

" Ignore compiled files
set wildignore=*.o,*~,*.pyc

" Always show current position
set ruler

" Set height of the command bar
set cmdheight=2

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it behaves properly
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" Be smart about case when searching
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw when executing macros
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets
set showmatch

" How many tenths of a second to blink when matching brackets
set mat=2

" Add a bit of margin to the left
set foldcolumn=1

" Enable syntax highlighting
syntax enable

" Set utf8 as standard encoding
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs
set smarttab

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4

" Linebreak at 500 characters
set lbr
set tw=500

" Auto indent
set ai

" Smart indent
set si

" Wrap lines
set wrap

" Treat long lines as break lines
map j gj
map k gk

" Map <space> to search and Ctrl-<space> to backwards search
map <space> /
map <c-space> ?

" Always show the status line
set laststatus=2

" Format the status line
set statusline=\ %{HasPaste()}%F%m%r%h\ %w\ \ CWD:\ %r%{getcwd()}%h\ \ \ Line:\ %l

" Delete trailing whitespace on save
func! DeleteTrailingWS()
    exe "normal mz"
    %s/\s\+$//ge
    exe "normal `z"
endfunc
autocmd BufWrite *.py :call DeleteTrailingWS()
autocmd BufWrite *.coffee :call DeleteTrailingWS()

" Pressing ,ss will toggle and untoggle spell checking
map <leader>ss :setlocal spell!<cr>

" Returns true if paste mode is enabled
function! HasPaste()
    if &paste
        return 'PASTE MODE  '
    endif
    return ''
endfunction
