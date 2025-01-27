"Kevin Jayne (kevin.jayne@icloud.com) vim configuration file

" For all text files set 'textwidth' to 78 characters.
autocmd FileType text setlocal textwidth=78

" Search Configuration
set ignorecase          " Case Insensitivity
set smartcase                       " Unless explict match
set incsearch                       " Highlight Matching as I type
set hlsearch                        " Highlight Matches

" Other
set updatetime=100        " mainly for git gutter update
set expandtab             " Set to use spaces not tabs
set title                 " Set the terminal title
set autoindent            " autoindent on CR
set copyindent            " copy previous indenting
set tabstop=2             " Global Tab Width
set shiftwidth=2          " number of spaces for auto-indent
set laststatus=2          " Show the statusline all the time
set hidden                " handle multiple buffers better
set autoindent            " always set autoindenting on
set paste                 " always allow paste
set number                " for line numbers
set expandtab             " spaces for tabs
set background=dark       " umm...
set backspace=indent,eol,start " default backspace behavior

" Force Defaults to UTF-8
set encoding=utf-8
set fileencoding=utf-8

" Enable Mouse Support with SGR (xterm 1006 mouse support for more lines)
set mouse+=a
if !has('nvim')
  set ttymouse=xterm2
endif

" VIM-Markdown Configuration
let g:vim_markdown_folding_disabled=1

" Coloring
syntax on
au BufNewFile,BufRead Jenkinsfile setf groovy
"set clipboard=unnamedplus
" yank to clipboard
" requires: 
"    brew install reattach-to-user-namespace 
"    brew install vim --with-client-server
"if has("clipboard")
  "set clipboard=unnamed " copy to the system clipboard

  "if has("unnamedplus") " X11 support
    "set clipboard+=unnamedplus
  "endif
"endif

" Set autoreading to on
set autoread
au CursorHold * checktime

" Install vim-plug:
" curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
" Vim Plug Auto Install:
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Specify a directory for plugins
" - For Neovim: ~/.local/share/nvim/plugged
" - Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')

" On-demand loading
Plug 'nathanaelkane/vim-indent-guides'
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'scrooloose/nerdcommenter'
Plug 'airblade/vim-gitgutter'
Plug 'bling/vim-airline'
Plug 'flazz/vim-colorschemes'
Plug 'scrooloose/syntastic'
Plug 'nathanaelkane/vim-indent-guides'

" Initialize plugin system
call plug#end()

" Colors
"colorscheme iceberg
"colorscheme molokai
"colorscheme dracula

" NERDTree Settings
let g:NERDTreeMouseMode=3
let g:NERDTreeWinSize=25
let NERDTreeShowHidden=1           " show hidden files
map <C-n> :NERDTreeToggle<CR>      " open NERDTree with Ctrl+n 
" Open NERDTree in new tabs and windows if no command line args set
" NERDTree is e.g. not helpful if you do a git commit or something similiar.
  autocmd VimEnter * if !argc() | NERDTree 
" exit vim when editor closed and nerdtree open
  autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Indent Guides Settings
let g:indent_guides_enable_on_vim_startup = 1
set ts=4 sw=4 et
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1 

" Numbers
function! NumberToggle()
  if(&number == 1)
    set norelativenumber
    set nonumber
  else
    set number
    "set relativenumber
  endif
endfunc
map <C-m> :call NumberToggle()<CR>

" Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
au!

" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
" Also don't do it when the mark is in the first line, that is the default
" position when opening a file.
"autocmd BufReadPost *
"  \ if line("'\"") > 1 && line("'\"") <= line("$") |
"  \   exe "normal! g`\"" |
"  \ endif
"
"augroup END

