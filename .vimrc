call plug#begin()

" On-demand loading
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'lervag/vimtex'
" Initialize plugin system
call plug#end()

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
set hlsearch
set is
set foldlevel   =9
set colorcolumn =80
set foldmethod  =indent
set ignorecase
set smartcase

let NERDTreeShowHidden=1
let mapleader         ="-"

" remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e
autocmd BufWritePost thesis.tex silent! make | redraw!
autocmd BufReadPre,FileReadPre .xmobarrc :set syntax=haskell
" remove trailing empty lines on save
" autocmd BufWritePre * :%s#\($\n\s*\)\+\%$##
" highlight portions of lines over 80 characters long
highlight ColorColumn ctermbg=darkgray

nnoremap <C-H> :vertical resize -5<RETURN>
nnoremap <C-L> :vertical resize +5<RETURN>
nnoremap <C-K> :resize -5<RETURN>
nnoremap <C-J> :resize +5<RETURN>
nnoremap <silent>  :NERDTreeToggle<RETURN>
nnoremap <silent>  :nohlsearch<RETURN>
inoremap <C-F> <right>
inoremap <C-B> <left>
inoremap <C-D> <delete>

augroup filetype_tex
    autocmd!
    autocmd FileType tex vnoremap <leader>i :<c-u>call TexCmdWrap("textit")<cr>
    autocmd FileType tex vnoremap <leader>b :<c-u>call TexCmdWrap("textbf")<cr>
    autocmd FileType tex vnoremap <leader>e :<c-u>call TexEnvWrap()<cr>
    autocmd FileType tex set complete-=i
augroup END

function TexEnvWrap()
    call inputsave()
    let envName = input('Environment name: ')
    call inputrestore()
    if strlen(envName)
        call TexEnvWrapHelper(envName)
    endif
endfunction

function TexEnvWrapHelper(envName)
    " indent the block
    normal! '<>'>
    " move to the end of the block
    normal! '>
    " insert ending tag
    execute "normal! o\\end{" . a:envName . "}"
    " move to the beginning of the block
    normal! '<
    " insert beginning tag one line after the correct position for correct
    " indentation
    execute "normal! o\\begin{" . a:envName . "}"
    " fix indentation
    normal! <<
    " move beginning tag to the correct position
    normal! ddkP
endfunction

function TexCmdWrap(command)
    normal! `>
    normal! a}
    normal! `<
    execute "normal! i\\" . a:command . "{"
endfunction

