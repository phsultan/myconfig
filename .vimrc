" -------------------------
" Basics
" -------------------------
set nocompatible
filetype plugin indent on
syntax on

set encoding=utf-8
set hidden
set autoread
set autowrite
set nobackup
set noswapfile
set updatetime=300
set termguicolors

" -------------------------
" UI
" -------------------------
set number
set ruler
set showcmd
set laststatus=2
set wildmenu
set wildmode=longest:full,list:full
set scrolloff=5
set splitright
set showmatch

let mapleader = ","

" Tabs
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set smartindent

" -------------------------
" Navigation
" -------------------------
nnoremap <C-Right> :bn<CR>
nnoremap <C-Left> :bp<CR>

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" -------------------------
" Comment toggling (kept from your config)
" -------------------------
augroup commenting_blocks_of_code
  autocmd!
  autocmd FileType c,cpp,java,javascript,go let b:comment_leader = '// '
  autocmd FileType sh,ruby,python           let b:comment_leader = '# '
  autocmd FileType vim                      let b:comment_leader = '" '
augroup END

noremap <silent> <Leader>cc :<C-B>silent <C-E>s/^/<C-R>=escape(b:comment_leader,'\/')<CR>/<CR>:nohlsearch<CR>
noremap <silent> <Leader>cu :<C-B>silent <C-E>s/^\s*\V<C-R>=escape(b:comment_leader,'\/')<CR>//e<CR>:nohlsearch<CR>

" -------------------------
" Plugins (vim-plug)
" -------------------------
call plug#begin('~/.vim/plugged')

" Fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Git integration (needed for your GGrep)
Plug 'tpope/vim-fugitive'

" Text objects and motions you relied on
Plug 'tpope/vim-unimpaired'

" Optional: lightweight completion (much lighter than YouCompleteMe)
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" -------------------------
" FZF config (modernized)
" -------------------------
let g:fzf_vim = {}
let g:fzf_vim.buffers_jump = 1

" Ripgrep-powered search
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --smart-case '.shellescape(<q-args>),
  \   fzf#vim#with_preview(), <bang>0)

" Git grep
command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number '.shellescape(<q-args>),
  \   fzf#vim#with_preview(), <bang>0)

" -------------------------
" Quickfix (kept)
" -------------------------
nnoremap <Leader>co :copen<CR>
nnoremap <Leader>cc :cclose<CR>
nnoremap <Leader>cp :cprev<CR>
nnoremap <Leader>cn :cnext<CR>

" -------------------------
" BuffersDelete (kept, cleaned)
" -------------------------
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
  \ 'options': '--multi --reverse'
\ }))
