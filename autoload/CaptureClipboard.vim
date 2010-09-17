" CaptureClipboard.vim: Append system clipboard changes to current buffer. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2010 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.00.001	18-Sep-2010	file creation

let s:save_cpo = &cpo
set cpo&vim

function! s:Message( ... )
    if &title
	if ! a:0
	    " Initial invocation: Save original title and set up autocmd to
	    " restore it in case the capturing is not stopped via "EOF", but by
	    " aborting the command. 
	    let s:save_titlestring = &titlestring
	    augroup CaptureClipboard
		au!
		" Note: The CursorMoved event is triggered immediately after a
		" CTRL-C if text has been inserted; the other events are not
		" triggered inside the loop. If no text has been captured, we
		" try to restore the title when the cursor moves or the window
		" changes. 
		au CursorHold,CursorMoved,WinLeave * let &titlestring = s:save_titlestring | autocmd! CaptureClipboard
	    augroup END
	endif

	let &titlestring = (a:0 ? a:1 . printf(' clip%s...', (a:1 == 1 ? '' : 's')) : 'Capturing...') . ' - %{v:servername}'
	redraw  " This is necessary to update the title. 
    endif

    echo printf('Capturing clipboard changes %sto current buffer. To stop, press <CTRL-C> or copy "EOF". ', (a:0 ? '(' . a:1 . ') ' : ''))
endfunction
function! s:EndMessage( count )
    redraw
    echo printf('Captured %s clipboard changes. ', (a:count > 0 ? a:count : 'no'))

    if &title
	autocmd! CaptureClipboard
	let &titlestring = s:save_titlestring
	unlet s:save_titlestring
    endif
endfunction

function! s:GetDelimiter( argument )
    try
	if a:argument =~# '^\([''"]\).*\1$' 
	    " The argument is quotes, evaluate it. 
	    execute 'let l:delimiter =' a:argument
	elseif a:argument =~# '\\' 
	    " The argument contains escape characters, evaluate them. 
	    execute 'let l:delimiter = "' . a:argument . '"'
	else
	    let l:delimiter = a:argument
	endif
    catch /^Vim\%((\a\+)\)\=:E/
	let l:delimiter = a:argument
    endtry
    return l:delimiter
endfunction
function! s:Insert( text, delimiter, isPrepend )
    let l:insertText = (a:isPrepend ? a:text . a:delimiter : a:delimiter . a:text)
    if l:insertText =~# (a:isPrepend ? '\n$' : '^\n')
	let l:insertText = (a:isPrepend ? strpart(l:insertText, 0, strlen(l:insertText) - 1) : strpart(l:insertText, 1))
	execute 'put' . (a:isPrepend ? '!' : '') '=l:insertText'
    else
	execute "normal! \"=l:insertText\<CR>" . (a:isPrepend ? 'Pg`[' : 'pg`]')
    endif
endfunction
function! CaptureClipboard#CaptureClipboard( isPrepend, isTrim, count, ... )
    if ! &l:modifiable
	let v:errmsg = "E21: Cannot make changes, 'modifiable' is off"
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return
    endif

    let l:delimiter = (a:0 ? s:GetDelimiter(a:1) : "\n")
    let l:firstDelimiter = (l:delimiter =~# '\n' ? "\n" : '')

    call s:Message()
    let l:captureCount = 0

    if @* ==# 'EOF'
	" Remove the EOF marker (from a previous :CaptureClipboard run) from the
	" clipboard, or else the capture won't even start. 
	let @* = ''
    endif

    let l:temp = @*
    while ! (@* ==# 'EOF' || (a:count && l:captureCount == a:count))
	if l:temp !=# @*
	    let l:temp = @*
	    call s:Insert(
	    \	(a:isTrim ? substitute(l:temp, '^\_s*\(.\{-}\)\_s*$', '\1', 'g') : l:temp),
	    \	(l:captureCount == 0 ? l:firstDelimiter : l:delimiter),
	    \	a:isPrepend
	    \)
	    let l:captureCount += 1

	    silent! write
	    redraw
	    call s:Message(l:captureCount)
	else
	    sleep 50ms
	endif
    endwhile

    call s:EndMessage(l:captureCount)
endfunction 

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
