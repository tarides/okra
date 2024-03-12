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
  <stdin>:3:No time found in "Everything is great"
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
  b.md:1:No time found in "Everything is great"
  b.md:1:No project found for "Everything is great"
  a.md:4:* used as bullet point, this can confuse the parser. Only use - as bullet marker.
  a.md:5:* used as bullet point, this can confuse the parser. Only use - as bullet marker.
  [1]
