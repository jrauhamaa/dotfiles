set clipboard=unnamedplus
syntax on
set autoindent
set expandtab
set tabstop     =4
set softtabstop =4
set shiftwidth  =4

" remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e
autocmd BufWritePost thesis.tex silent! make | redraw!
" remove trailing empty lines on save
" autocmd BufWritePre * :%s#\($\n\s*\)\+\%$##
" highlight portions of lines over 80 characters long
highlight ColorColumn ctermbg=darkgray
call matchadd('ColorColumn', '\%>80v', 100)
