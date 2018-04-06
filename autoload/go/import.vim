" Change imports of the current buffer.
"
" add:   add import; if 0 it will remove the import
" alias: import alias
" path:  import path
" bang:  go get if packages don't exist
function! go#import#SwitchImport(add, alias, path, bang) abort
  let l:path = a:path
  if l:path is# ''
    call go#util#EchoError('import path not provided')
    return
  endif

  let l:cmd = ['goimport', '-json', (a:add ? '-replace' : '-rm'),
        \ (a:alias isnot? '' ? a:path . ':' . a:alias : a:path)]
  if a:bang is# '!'
    let l:cmd += ['-get']
  endif

  let [l:out, l:err] = go#util#Exec(l:cmd, join(go#util#GetLines(), "\n"))
  if l:err
    call go#util#EchoError(l:out)
    return
  endif
  try
    let l:json = json_decode(l:out)
  catch
    call go#util#EchoError(l:out)
    return
  endtry

  let l:code = split(l:json['code'], "\n")
  let l:view = winsaveview()
  let l:lastline = line('$')
  try
    " No imports yet; go to the corect line.
    if l:json['end'] is 0
      exe 'normal! ' . l:json['start'] . 'go'
    " Remove existing imports.
    else
      silent exe 'normal! ' . l:json['start'] . 'gov' . l:json['end'] . 'gox'
    endif

    " Add imports.
    call setline('.', l:code[0])
    call append('.', l:code[1:])
  finally
    " Adjust view for any changes.
    let l:view.lnum += line('$') - l:lastline
    let l:view.topline += line('$') - l:lastline
    if l:view.topline < 0
      let l:view.topline = 0
    endif
    call winrestview(l:view)
  endtry
endfunction

" vim: sw=2 ts=2 et
