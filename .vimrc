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
    autocmd FileType tex vnoremap <leader>i :<c-u>call TexCmdWrap("textit", "<", ">", "char")<cr>
    autocmd FileType tex nnoremap <leader>i :set opfunc=TexItalicHelper<cr>g@
    autocmd FileType tex vnoremap <leader>b :<c-u>call TexCmdWrap("textbf", "<", ">", "char")<cr>
    autocmd FileType tex nnoremap <leader>b :set opfunc=TexBoldHelper<cr>g@
    autocmd FileType tex vnoremap <leader>e :<c-u>call TexEnvWrap("<", ">")<cr>
    autocmd FileType tex nnoremap <leader>e :set opfunc=TexEnvWrapOp<cr>g@
    autocmd FileType tex set complete-=i
augroup END

function TexEnvWrapOp(type)
    call TexEnvWrap("[", "]")
endfunction

function TexEnvWrap(mBegin, mEnd)
    call inputsave()
    let envName = input('Environment name: ')
    call inputrestore()
    if strlen(envName)
        call TexEnvWrapHelper(envName, a:mBegin, a:mEnd)
    endif
endfunction

function TexEnvWrapHelper(envName, mBegin, mEnd)
    execute "normal! '" . a:mBegin . "v'" . a:mEnd . "$h"
    execute "normal! s\\begin{" . a:envName . "}\"\\end{" . a:envName . "}"
endfunction

function TexCmdWrap(texCommand, mBegin, mEnd, type)
    if a:type == "char"
        let vCommand = "`" . a:mBegin . "v`" . a:mEnd
    else
        let vCommand = "'" . a:mBegin . "v'" . a:mEnd . "$h"
    endif
    execute "normal! " . vCommand . "s\\" . a:texCommand . "{}"
    normal! ""P
endfunction

function TexBoldHelper(type)
    call TexCmdWrap("textbf", "[", "]", a:type)
endfunction

function TexItalicHelper(type)
    call TexCmdWrap("textit", "[", "]", a:type)
endfunction

