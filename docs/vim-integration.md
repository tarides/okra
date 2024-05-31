# Vim integration

## `okra lint` as a syntastic checker

`okra lint` can be used as a checker for [syntastic]. When this is set up, `okra
lint` are displayed with location info (or available in the quickfix list).

To do so, set up this repository as a vim plugin. For example with [vim-plug],
add this line to the list of plugins in `~/.vimrc`:

```vim
Plug 'tarides/okra'
```

By default, checkers are not active so a manual `:SyntasticCheck okra` is
necessary to trigger the check. Having the check by default for all markdown
files is not desirable because most markdown is not understood by `okra`. But it
is possible to enable it in certain directories. This can be done by adding the
following line in `~/.vimrc`:

```vim
autocmd BufRead,BufNewFile ~/src/weekly-reports/* let g:syntastic_markdown_checkers = ['okra']
```

[syntastic]: https://github.com/vim-syntastic/syntastic
[vim-plug]: https://github.com/junegunn/vim-plug

## Workitem name completion

While not strictly related to `okra` it can be handy to complete objective names from a
fixed list.

To do so it is possible to rely on the `fzf.vim` plugin:

```vim
" In the plugin section
Plug 'junegunn/fzf.vim'

" Later
inoremap <expr> <c-x><c-k> fzf#vim#complete('cat /path/to/.objectives')
```

And create a file at `/path/to/.objectives` with one line per objective, for example:

```
- libsomething supports Windows (#101)
- program P is integrated with dune (#102)
```

Now when in insert mode, <kbd>Ctrl</kbd>+<kbd>X</kbd> followed by
<kbd>Ctrl</kbd>+<kbd>K</kbd> will fuzzy complete lines in that file.
