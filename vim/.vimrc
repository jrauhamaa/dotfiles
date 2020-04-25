set clipboard=unnamedplus
syntax on
set autoindent
set expandtab
set tabstop     =4
set softtabstop =4
set shiftwidth  =4

" remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e
" remove trailing empty lines on save
autocmd BufWritePre * :%s#\($\n\s*\)\+\%$##
