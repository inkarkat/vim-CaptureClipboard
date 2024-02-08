" CaptureClipboard.vim: Append system clipboard changes to current buffer.
"
" DEPENDENCIES:
"   - ingo-library.vim plugin
"
" Copyright: (C) 2010-2024 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
let s:save_cpo = &cpo
set cpo&vim

function! s:PreCapture()
    " Disable folding; it may obscure what's being captured.
    let s:save_foldenable = &foldenable
    set nofoldenable

    " Save original title.
    if &title
	let s:save_titlestring = &titlestring
    endif

    " Set up autocmd to restore settings in case the capturing is not stopped
    " via the end-of-capture marker, but by aborting the command.
    augroup CaptureClipboard
	autocmd!
	" Note: The CursorMoved event is triggered immediately after a CTRL-C if
	" text has been inserted; the other events are not triggered inside the
	" loop. If no text has been captured, we try to restore the settings
	" when the cursor moves or the window changes.
	autocmd CursorHold,CursorMoved,WinLeave * call s:PostCapture() | autocmd! CaptureClipboard
    augroup END
endfunction
function! s:PostCapture()
    if exists('s:save_titlestring')
	let &titlestring = s:save_titlestring
	unlet s:save_titlestring
    endif

    if exists('s:save_foldenable')
	let &foldenable = s:save_foldenable
	unlet s:save_foldenable
    endif
endfunction

function! s:Message( ... )
    if &title
	let &titlestring = (a:0 ? a:1 . printf(' clip%s...', (a:1 == 1 ? '' : 's')) : 'Capturing...') . ' - %{v:servername}'
    endif

    redraw  " Update the window with the pasted contents; this is also necessary to update the title.

    echo printf('Capturing clipboard changes %sto current buffer. To stop, press <CTRL-C> or copy "%s". ',
    \	(a:0 ? '(' . a:1 . ') ' : ''),
    \	strtrans(g:CaptureClipboard_EndOfCaptureMarker)
    \)
endfunction
function! s:EndMessage( count )
    redraw
    echo printf('Captured %s clipboard changes. ', (a:count > 0 ? a:count : 'no'))
endfunction

function! s:GetClipboard( register )
    return getreg(a:register)
endfunction
function! s:ClearClipboard( register )
    call setreg(a:register, '')
endfunction

function! s:Insert( text, isPrepend )
    if a:text =~# (a:isPrepend ? '\n$' : '^\n')
	let l:insertText = (a:isPrepend ? strpart(a:text, 0, strlen(a:text) - 1) : strpart(a:text, 1))
	silent call ingo#lines#PutWrapper('.', 'put' . (a:isPrepend ? '!' : ''), l:insertText)
    else
	execute "silent normal! \"=a:text\<CR>" . (a:isPrepend ? 'Pg`[' : 'pg`]')
    endif
endfunction
function! CaptureClipboard#CaptureClipboard( register, isPrepend, isTrim, count, ... )
    if a:0 && a:1 =~# '\r'
	let l:results = map(split(a:1, '\r', 1), 'ingo#cmdargs#GetUnescapedExpr(v:val)')
	if len(l:results) == 2
	    let [l:prefix, l:suffix] = l:results
	    let [l:firstPrefix, l:firstSuffix] = [l:prefix, l:suffix]
	elseif len(l:results) == 3
	    let [l:prefix, l:suffix] = (a:isPrepend ? [l:results[0], l:results[2] . l:results[1]] : [l:results[1] . l:results[0], l:results[2]])
	    let [l:firstPrefix, l:firstSuffix] = [l:results[0], l:results[2]]
	elseif len(l:results) == 4
	    let [l:prefix, l:suffix] = (a:isPrepend ? [l:results[1], l:results[3] . l:results[2]] : [l:results[2] . l:results[1], l:results[3]])
	    let [l:firstPrefix, l:firstSuffix] = [l:results[0], l:results[3]]
	else
	    call ingo#err#Set('Additional argument(s): ' . join(l:results[4:], '^M'))
	    return 0
	endif
    else
	let l:delimiter = (a:0 ? ingo#cmdargs#GetStringExpr(a:1) : g:CaptureClipboard_DefaultDelimiter)
	let l:firstDelimiter = (l:delimiter =~# '\n' ? "\n" : '')   " When {delimiter} contains a newline character, the first capture will already start on a new line.
	let [l:prefix, l:suffix] = (a:isPrepend ? ['', l:delimiter] : [l:delimiter, ''])
	let [l:firstPrefix, l:firstSuffix] = (a:isPrepend ? [l:firstDelimiter, ''] : ['', l:firstDelimiter])
    endif

    call s:PreCapture()
    call s:Message()
    let l:captureCount = 0

    if s:GetClipboard(a:register) ==# g:CaptureClipboard_EndOfCaptureMarker
	" Remove the end-of-capture marker (from a previous :CaptureClipboard run) from the
	" clipboard, or else the capture won't even start.
	call s:ClearClipboard(a:register)
    endif

    let l:temp = s:GetClipboard(a:register)
    while ! (s:GetClipboard(a:register) ==# g:CaptureClipboard_EndOfCaptureMarker || (a:count && l:captureCount == a:count))
	if l:temp !=# s:GetClipboard(a:register)
	    let l:temp = s:GetClipboard(a:register)
	    let l:text = (a:isTrim ? ingo#str#Trim(l:temp) : l:temp)
	    call s:Insert(
	    \	(l:captureCount == 0 ? l:firstPrefix : l:prefix) .
	    \	    l:text .
	    \	    (l:captureCount == 0 ? l:firstSuffix : l:suffix),
	    \	a:isPrepend
	    \)
	    let l:captureCount += 1

	    if g:CaptureClipboard_IsAutoSave
		silent! noautocmd write
	    endif

	    call s:Message(l:captureCount)
	else
	    sleep 50ms
	endif
    endwhile

    call s:EndMessage(l:captureCount)
    autocmd! CaptureClipboard
    call s:PostCapture()
    return 1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
