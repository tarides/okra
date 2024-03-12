Lint can read from a file:

  $ cat > err.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - Do it
  > EOF
  $ okra lint err.md
  [ERROR(S)]: err.md
  
  In KR "Everything is great":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]

It can also read from stdin:

  $ okra lint < err.md
  [ERROR(S)]: <stdin>
  
  In KR "Everything is great":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]

If everything is fine, nothing is printed and it exits with 0:

  $ cat > ok.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (5 days)
  >   - Do it
  > EOF

  $ okra lint ok.md
  [OK]: ok.md
  $ okra lint < ok.md
  [OK]: <stdin>

When errors are found in several files, they are all printed:

  $ cat > err2.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a
  >   - Do it
  > EOF
  $ okra lint err.md err2.md
  [ERROR(S)]: err2.md
  
  In KR "Everything is great":
    Invalid time entry "@a" found. Format is '- @eng1 (x days), @eng2 (y days)'
    where x and y must be divisible by 0.5
  [ERROR(S)]: err.md
  
  In KR "Everything is great":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]
