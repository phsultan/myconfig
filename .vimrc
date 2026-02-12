" Not compatible with vi
set nocompatible


" ------- From https://github.com/Chewie/dotfiles/blob/master/vim/.vimrc
" Enable filetype detection for plugins and indentation options
filetype plugin indent on

" Reload a file when it is changed from the outside
set autoread

" Write the file when we leave the buffer
set autowrite

" Disable backups, we have source control for that
set nobackup

" Force encoding to utf-8, for systems where this is not the default (windows
" comes to mind)
set encoding=utf-8

" Disable swapfiles too
set noswapfile

" Hide buffers instead of closing them
set hidden

" Set the time (in milliseconds) spent idle until various actions occur
" In this configuration, it is particularly useful for the tagbar plugin
set updatetime=500

" For some stupid reason, vim requires the term to begin with "xterm", so the
" automatically detected "rxvt-unicode-256color" doesn't work.
set term=xterm-256color

" set autochdir

""""""""""""""""""""""""""""""""""""""""""""""""""

" User interface

""""""""""""""""""""""""""""""""""""""""""""""""""

" Make backspace behave as expected
set backspace=eol,indent,start

" Set the minimal amount of lignes under and above the cursor
" Useful for keeping context when moving with j/k
set scrolloff=5

" Show current mode
set showmode

" Show command being executed
set showcmd

" Always show status line
set laststatus=2

" Format the status line
" This status line comes from Pierre Bourdon's vimrc
"set statusline=%f\ %l\|%c\ %m%=%p%%\ (%Y%R)

" Enhance command line completion
set wildmenu

" Set completion behavior, see :help wildmode for details
set wildmode=longest:full,list:full

" Disable bell completely
set visualbell
set t_vb=

" Enables syntax highlighting
syntax on

" Use new regular expression engine
" Needed otherwise Typescript files fail to load or highlight syntax
" Reference : https://jameschambers.co.uk/vim-typescript-slow
set re=0

" Allow mouse use in vim
" set mouse=a

" Briefly show matching braces, parens, etc
set showmatch

" Show ruler (line number + column number)
set ruler

" Show line numnber
set number

" Pop window on the right side when splitting vertically
set splitright

" Set the <Leader> key to ',' ( '\' being the default)
let mapleader = ","

" Commenting blocks of code.
" Source : https://stackoverflow.com/a/1676672/4313251
augroup commenting_blocks_of_code
  autocmd!
  autocmd FileType c,cpp,java,javascript,scala,vue,go let b:comment_leader = '// '
  autocmd FileType sh,ruby,python                     let b:comment_leader = '# '
  autocmd FileType conf,fstab                         let b:comment_leader = '# '
  autocmd FileType tex                                let b:comment_leader = '% '
  autocmd FileType mail                               let b:comment_leader = '> '
  autocmd FileType vim                                let b:comment_leader = '" '
augroup END

noremap <silent> <Leader>cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:nohlsearch<CR>
noremap <silent> <Leader>cu :<C-B>silent <C-E>s/^\s*\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:nohlsearch<CR>

set tabstop=2
set softtabstop=2
set shiftwidth=2
set autoindent
set expandtab
set smartindent


nnoremap <C-Right> :bn<Enter>
nnoremap <C-Left> :bp<Enter>

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

let g:ale_fix_on_save = 1

" Map <,> to [,] for the vim-unimpaired plugin to work. See :
" https://github.com/tpope/vim-unimpaired"
nmap < [
nmap > ]
omap < [
omap > ]
xmap < [
xmap > ]

" Ignore terminal when switching buffers
" augroup termIgnore
"   autocmd!
"   autocmd TerminalOpen * set nobuflisted
" augroup END

" Initialize configuration dictionary
let g:fzf_vim = {}

let g:fzf_vim.buffers_jump = 1


command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number -- '.fzf#shellescape(<q-args>),
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)

" shorter version of GGrep above, with fugitive
command RRg Gcd | Rg

" vim-go
let g:go_fmt_command = "goimports"
let g:go_autodetect_gopath = 1
let g:go_list_type = "quickfix"
let g:go_def_mode = "gopls"

let g:go_highlight_operators = 1
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_function_calls = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_generate_tags = 1

au FileType go nmap <Leader>dv <Plug>(go-def-vertical)
""""" End vim-go

""""" Quickfix 
" Clear quickfix list
function ClearQuickfixList()
  call setqflist([])
endfunction
command! ClearQuickfixList call ClearQuickfixList()
nmap <leader>cf :ClearQuickfixList<cr>
" End of Clear quickfix list

" Show the quickfix window
nnoremap <Leader>co :copen<CR>

" Hide the quickfix window
nnoremap <Leader>cc :cclose<CR>

" Go to the previous location
nnoremap <Leader>cp :cprev<CR>

" Go to the next location
nnoremap <Leader>cn :cnext<CR>
""""" End Quickfix 

let g:netrw_winsize = 25

" close all buffers except current one
command! BufCurOnly execute '%bdelete|edit#|bdelete#'

""""" Remove buffers
" Incredible function that allows you to selectively remove buffers
" From https://github.com/junegunn/fzf.vim/pull/733#issuecomment-559720813
function! s:list_buffers()
  redir => list
  silent ls
  redir END
  return split(list, "\n")
endfunction

function! s:delete_buffers(lines)
  execute 'bwipeout' join(map(a:lines, {_, line -> split(line)[0]}))
endfunction

command! BuffersDelete call fzf#run(fzf#wrap({
  \ 'source': s:list_buffers(),
  \ 'sink*': { lines -> s:delete_buffers(lines) },
  \ 'options': '--multi --reverse --bind ctrl-a:select-all+accept'
\ }))
""""" End Remove buffers

""""" YouCompleteMe
let g:ycm_autoclose_preview_window_after_completion = 1
inoremap <expr> <CR> pumvisible() ? "\<C-Y>" : "\<CR>"
""""" End YouCompleteMe
