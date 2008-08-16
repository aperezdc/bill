" bill.vim
"
" Author:   Adrian Perez <aperez@igalia.com>
" Date:     2008-08-16
"
" Vim plugin with extras for syntax-highlighting Bill modules and scripts.
" Copy to ~/.vim/plugins or to the system-wide plugins directory.
"


augroup Bill
	autocmd!
	autocmd BufWinEnter * call <sid>CLoad()
	set ft=bill
augroup End

" Function: CLoad
" Purpose:	Load specified syntax higlighting for Bill scripts.
"
function <sid>CLoad()
	if getline(1) =~ "^#!.*bill.*"

		" Load SH as "bash"

		call SetFileTypeSH("bash")
		setlocal expandtab tabstop=4 shiftwidth=4

		" Modify bash Todo environment

		syn cluster  shCommentGroup    contains=shTodo,@Spell
		syn keyword  shTodo            contained TODO XXX FIXME
		syn match    shComment "#.*$"  contains=@shCommentGroup
		syn keyword  shStatement       use need warn die

	endif
endfunction


