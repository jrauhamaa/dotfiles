"{{{plugins

call plug#begin()

" On-demand loading
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'lervag/vimtex'
" Initialize plugin system
call plug#end()

"}}}

"{{{global settings

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

" highlight portions of lines over 80 characters long
highlight ColorColumn ctermbg=darkgray

"}}}

"{{{global mappings

nnoremap <C-H> :vertical resize -5<RETURN>
nnoremap <C-L> :vertical resize +5<RETURN>
nnoremap <C-K> :resize -5<RETURN>
nnoremap <C-J> :resize +5<RETURN>
nnoremap <silent>  :NERDTreeToggle<RETURN>
nnoremap <silent>  :nohlsearch<RETURN>
"emacs
inoremap <C-F> <right>
inoremap <C-B> <left>
inoremap <C-D> <delete>
inoremap <C-A> <home>
inoremap <C-E> <end>
inoremap <C-@> <space>
"ctrl-arrow
inoremap [1;5C <right>
inoremap [1;5D <left>
inoremap [1;5B <down>
inoremap [1;5A <up>
nnoremap [1;5C <right>
nnoremap [1;5D <left>
nnoremap [1;5B <down>
nnoremap [1;5A <up>
vnoremap [1;5C <right>
vnoremap [1;5D <left>
vnoremap [1;5B <down>
vnoremap [1;5A <up>
"cyrillic
nnoremap <leader>r :call Translate('Russian phrase', russianDict)<cr>
nnoremap <leader>u :call Translate('Ukrainian phrase', ukrainianDict)<cr>
vnoremap <silent> <leader>r :<c-u>call TranslateRegion('char', '<', '>', russianDict)<cr>
vnoremap <silent> <leader>u :<c-u>call TranslateRegion('char', '<', '>', ukrainianDict)<cr>
nnoremap <silent> <leader>R :set opfunc=RussianRegion<cr>g@
nnoremap <silent> <leader>U :set opfunc=UkrainianRegion<cr>g@

"}}}

"{{{autocmd

" remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e
autocmd BufReadPre,FileReadPre .xmobarrc :set syntax=haskell

augroup filetype_vim
    autocmd!
    autocmd FileType vim set foldmethod=marker
augroup END

augroup filetype_tex
    autocmd!
    autocmd FileType tex vnoremap <leader>i :<c-u>call TexCmdWrap("textit", "<", ">", "char")<cr>
    autocmd FileType tex nnoremap <silent> <leader>i :set opfunc=TexItalicHelper<cr>g@
    autocmd FileType tex vnoremap <leader>b :<c-u>call TexCmdWrap("textbf", "<", ">", "char")<cr>
    autocmd FileType tex nnoremap <silent> <leader>b :set opfunc=TexBoldHelper<cr>g@
    autocmd FileType tex vnoremap <leader>e :<c-u>call TexEnvWrap("<", ">")<cr>
    autocmd FileType tex nnoremap <silent> <leader>e :set opfunc=TexEnvWrapOp<cr>g@
    autocmd FileType tex set complete-=i
augroup END

"}}}

"{{{latex

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

"}}}

"{{{cyrillic

function ReadDict(path)
    let d = {}
    for line in readfile(a:path)
        let [upperTarget, lowerTarget, upperSource, lowerSource] = split(line, ',')
        let d[upperSource] = upperTarget
        let d[lowerSource] = lowerTarget
    endfor
    return d
endfunction

let russianDict = ReadDict('/home/joppe/russian.csv')
let ukrainianDict = ReadDict('/home/joppe/ukrainian.csv')

function TranslateCharacter(phrase, dictionary)
    let pLen = strlen(a:phrase)
    for n in range(pLen, 0, -1)
        let subP = a:phrase[0:n-1]
        if has_key(a:dictionary, subP)
            return [a:dictionary[subP], a:phrase[n:]]
        endif
    endfor
    throw "Invalid phrase: '" . a:phrase . "'"
endfunction

function TranslatePhrase(phrase, dictionary)
    let translation = ''
    let unTranslated = a:phrase

    while strlen(unTranslated)
        let c = unTranslated[0]
        if !('a' <=# c && c <=# 'z') && !('A' <=# c && c <=# 'Z')
            let translation = translation . c
            let unTranslated = unTranslated[1:]
            continue
        endif
        let [nextC, unTranslated] = TranslateCharacter(unTranslated, a:dictionary)
        let translation = translation . nextC
    endwhile
    return translation
endfunction

function Translate(message, dictionary)
    call inputsave()
    let sourceP = input(a:message . ': ')
    call inputrestore()
    redraw
    if !strlen(sourceP)
        return
    endif

    try
        let targetP = TranslatePhrase(sourceP, a:dictionary)
        execute "normal! a" . targetP
    catch /.*/
        echohl ErrorMsg
        echo v:exception
        echohl None
    endtry
endfunction

function TranslateRegion(type, mStart, mEnd, dictionary)
    " visual block mode not supported
    let [line1, col1] = getpos("'" . a:mStart)[1:2]
    let [line2, col2] = getpos("'" . a:mEnd)[1:2]

    let lines = getline(line1, line2)
    let lineHead = (a:type == "char" && col1 > 1) ? lines[0][:col1-2] : ''
    let lineTail = a:type == "char" ? lines[-1][col2:] : ''
    if a:type == "char"
        let lines[-1] = lines[-1][:col2-1]
        let lines[0] = lines[0][col1-1:]
    endif

    let translatedLines = []
    for line in lines
        let tLine = TranslatePhrase(line, a:dictionary)
        call add(translatedLines, tLine)
    endfor
    let translatedLines[0] = lineHead . translatedLines[0]
    let translatedLines[-1] = translatedLines[-1] . lineTail

    for n in range(line2 - line1 + 1)
        call setline(line1 + n, translatedLines[n])
    endfor
endfunction

function RussianRegion(type)
    call TranslateRegion(a:type, '[', ']', g:russianDict)
endfunction

function UkrainianRegion(type)
    call TranslateRegion(a:type, '[', ']', g:ukrainianDict)
endfunction

"}}}
