if exists('g:loaded_vim_test_rex')
  finish
endif
let g:loaded_vim_test_rex = 1

let s:block_id = ''

function! s:rex(args) abort
  let l:output = system(join(map(['rex', '-s', $REX_SESSION] + a:args, 'shellescape(v:val)')))
  return [l:output, v:shell_error]
endfunction

function! s:error(message) abort
  echohl ErrorMsg
  echomsg 'vim-test-rex: ' . a:message
  echohl None
endfunction

function! s:split() abort
  let [l:output, l:status] = s:rex([
        \ 'split', '-b', $REX_BLOCK, '--split=below', '--ratio', '30',
        \ '--focus=false', '-c', getcwd(), '--json',
        \ ])
  if l:status != 0
    call s:error("failed to split pane\n" . l:output)
    return 0
  endif
  let s:block_id = matchstr(l:output, '"block_ids"\_s*:\_s*\[\_s*"\zs[^"]*')
  if empty(s:block_id)
    call s:error("unexpected split output\n" . l:output)
  endif
  return !empty(s:block_id)
endfunction

function! RexStrategy(cmd) abort
  if empty($REX_SESSION) || empty($REX_BLOCK)
    call s:error('REX_SESSION and REX_BLOCK are not set')
    return
  endif

  " A trailing newline submits the line, so one send replaces send + send-key.
  let l:input = (get(g:, 'test#preserve_screen', -1) == 0 ? "clear\n" : '') . a:cmd . "\n"

  " Send straight to the known pane; split a new one only if that fails (pane closed).
  if !empty(s:block_id) && s:rex(['send', '-b', s:block_id, l:input])[1] == 0
    return
  endif
  if s:split()
    call s:rex(['send', '-b', s:block_id, l:input])
  endif
endfunction

function! s:close() abort
  if !empty(s:block_id)
    call s:rex(['block', 'close', s:block_id])
    let s:block_id = ''
  endif
endfunction

let g:test#custom_strategies = get(g:, 'test#custom_strategies', {})
let g:test#custom_strategies.rex = function('RexStrategy')
command! RexCloseRunner call <SID>close()
