Short mode exits with 0 when there is no error:

  $ okra lint --short << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (5 days)
  >   - Did everything
  > EOF

And with 1 when there is an error:

  $ okra lint --short << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - Did everything
  > EOF
  File <stdin>, line 3:
  Error: No time found in "Everything is great (E1)"
  [1]

This also works with files:

  $ cat > a.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   * @a (5 days)
  >   * Did everything
  > EOF

  $ cat > b.md << EOF
  > - Everything is great (E1)
  >   - Did everything
  > EOF

  $ okra lint --short a.md b.md
  File b.md, line 1:
  Error: No time found in "Everything is great (E1)"
  File b.md, line 1:
  Error: No project found for "Everything is great (E1)"
  File a.md, line 4:
  Error: * used as bullet point, this can confuse the parser. Only use - as bullet marker.
  File a.md, line 5:
  Error: * used as bullet point, this can confuse the parser. Only use - as bullet marker.
  [1]
