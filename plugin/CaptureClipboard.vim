" CaptureClipboard.vim: Append system clipboard changes to current buffer. 
"
" Maintainer:	Marian Csontos
" REVISION	DATE		REMARKS 
"	002	23-Sep-2009	Renamed from TrackClipboard to CaptureClipboard. 
"				ENH: Directly updating the window after each
"				capture, not every 5s. 
"				ENH: Capture is inserted below current line, not
"				necessarily at the end of the buffer. 
"				ENH: <bang> can be used to revert insertion, and
"				prepend instead of appending. (Analog to the
"				:put command.) 
"				BUG: Remove the EOF marker, or else the capture
"				won't even start. 
"				BUG: Silently ignoring autosave failures, the
"				user can deal with them after capturing is
"				finished. 
"				ENH: Checking for 'nomodifiable' buffer. 
"				ENH: Progress and end messages list number of
"				captures. 
"	001	26-Oct-2006	file creation from vimtip #1370

" Avoid installing twice or when in compatible mode
if exists('g:loaded_CaptureClipboard')
    finish
endif
let g:loaded_CaptureClipboard = 1

function! s:Message( ... )
    echo 'Capturing clipboard changes ' . (a:0 ? '(' . a:1 . ') ' : '') . 'to current buffer. To stop, press <CTRL-C> or copy "EOF". '
endfunction
function! s:EndMessage( count )
    redraw
    echo 'Captured ' . (a:count > 0 ? a:count : 'no') . ' clipboard changes. '
endfunction

function! s:CaptureClipboard( bang, count, ... )
    if ! &l:modifiable
	let v:errmsg = "E21: Cannot make changes, 'modifiable' is off"
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
	return
    endif

    if a:count > 0
	" Go to specified line number. (Will probably mostly used with
	" :$CaptureClipboard to append to the end of the buffer.) 
	execute a:count
    endif

    let l:delimiter = (a:0 ? a:1 : '')
    call s:Message()
    let l:captureCount = 0

    if @* ==# 'EOF'
	" Remove the EOF marker (from a previous :CaptureClipboard run) from the
	" clipboard, or else the capture won't even start. 
	let @* = ''
    endif

    let l:temp = @*
    while @* !=# 'EOF'
	if l:temp !=# @*
	    let l:temp = @*
	    if ! empty( l:delimiter )
		execute 'put' . a:bang '=l:delimiter'
	    endif
	    execute 'put' . a:bang '=l:temp'
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

command! -bang -range=-1 -nargs=? CaptureClipboard call <SID>CaptureClipboard('<bang>', <count>, <f-args>)

