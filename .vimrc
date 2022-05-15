set clipboard=unnamedplus
syntax on
set autoindent
set expandtab
set tabstop     =4
set softtabstop =4
set shiftwidth  =4
set nowrap
set history     =200
set nu
set colorcolumn =80

let NERDTreeShowHidden=1

" remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e
autocmd BufWritePost thesis.tex silent! make | redraw!
autocmd BufReadPre,FileReadPre .xmobarrc :set syntax=haskell
" remove trailing empty lines on save
" autocmd BufWritePre * :%s#\($\n\s*\)\+\%$##
" highlight portions of lines over 80 characters long
highlight ColorColumn ctermbg=darkgray

nmap oo o<Esc>k
nmap OO O<Esc>j
nmap <C-H> :vertical resize -5<RETURN>
nmap <C-L> :vertical resize +5<RETURN>
nmap <C-K> :resize -5<RETURN>
nmap <C-J> :resize +5<RETURN>
map   :NERDTreeToggle<RETURN>
