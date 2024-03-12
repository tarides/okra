Types of errors
---------------

No KR ID found:

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  [ERROR(S)]: <stdin>
  
  In KR "This is a KR":
    No KR ID found. WIs should be in the format "This is a WI (#123)", where 123 is the WI issue ID. Legacy KRs should be in the format "This is a KR (PLAT123)", where PLAT123 is the KR ID. For WIs that don't have an ID yet, use "New WI" and for work without a WI use "No WI".
  [1]

  $ okra lint << EOF
  > - This is a KR (KR123)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  [ERROR(S)]: <stdin>
  
  In KR "This is a KR": No project found (starting with '#')
  [1]

No work items found:

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KRID)
  >   - @eng1 (1 day)
  > EOF
  [ERROR(S)]: <stdin>
  
  In KR "This is a KR (KRID)":
    No work items found. This may indicate an unreported parsing error. Remove the KR if it is without work.
  [1]

No time entry found:

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR12)
  >   - My work
  >   - @eng1 (1 day)
  > EOF
  [ERROR(S)]: <stdin>
  
  In KR "This is a KR":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]

Multiple time entries:

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR12)
  >   - @eng1 (1 day)
  >   - My work
  >   - @eng2 (2 days)
  >   - More work
  > EOF
  [ERROR(S)]: <stdin>
  
  In KR "This is a KR":
    Multiple time entries found. Only one time entry should follow immediately after the KR.
  [1]

Format errors

  $ cat > err-bullet.md << EOF
  > # Title
  > 
  > - This is a KR (KRID)
  >   - @eng1 (1 day)
  >   + My work
  > EOF
  $ okra lint err-bullet.md
  [ERROR(S)]: err-bullet.md
  
  Line 5: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
  1 formatting errors found. Parsing aborted.
  [1]
  $ okra lint --short < err-bullet.md
  <stdin>:5:+ used as bullet point, this can confuse the parser. Only use - as bullet marker.
  [1]
  $ cat > err-space-title.md << EOF
  >  # Title
  > 
  > - This is a KR (KRID)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  $ okra lint err-space-title.md
  [ERROR(S)]: err-space-title.md
  
  Line 1: Space found before title marker #. Start titles in first column.
  1 formatting errors found. Parsing aborted.
  [1]
  $ okra lint --short err-space-title.md
  err-space-title.md:1:Space found before title marker #. Start titles in first column.
  [1]

  $ cat > err-space-indent.md << EOF
  > # Title
  > 
  >  - This is a KR (KRID)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  $ okra lint err-space-indent.md
  [ERROR(S)]: err-space-indent.md
  
  Line 3: Single space used for indentation (' - text'). Remove or replace by 2 or more spaces.
  1 formatting errors found. Parsing aborted.
  [1]
  $ okra lint --short err-space-indent.md
  err-space-indent.md:3:Single space used for indentation (' - text'). Remove or replace by 2 or more spaces.
  [1]

  $ cat > err-no-time.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - Did everything
  > EOF
  $ okra lint err-no-time.md
  [ERROR(S)]: err-no-time.md
  
  In KR "Everything is great":
    No time entry found. Each KR must be followed by '- @... (x days)'
  [1]
  $ okra lint --short err-no-time.md
  err-no-time.md:3:No time found in "Everything is great"
  [1]

  $ cat > err-invalid-time.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (day)
  >   - Did everything
  > EOF
  $ okra lint err-invalid-time.md
  [ERROR(S)]: err-invalid-time.md
  
  In KR "@a (day)":
    Invalid time entry found.
     Format is '- @eng1 (x days), @eng2 (y days)
     where x and y must be divisible by 0.5'
  [1]
  $ okra lint --short err-invalid-time.md
  err-invalid-time.md:4:Invalid time in "@a (day)"
  [1]

  $ cat > err-multiple-time.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (1 day)
  >   - @a (1 day)
  >   - Did everything
  > EOF
  $ okra lint err-multiple-time.md
  [ERROR(S)]: err-multiple-time.md
  
  In KR "Everything is great":
    Multiple time entries found. Only one time entry should follow immediately after the KR.
  [1]
  $ okra lint --short err-multiple-time.md
  err-multiple-time.md:3:Multiple time entries for "Everything is great"
  [1]

  $ cat > err-no-work.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (1 day)
  > EOF
  $ okra lint err-no-work.md
  [ERROR(S)]: err-no-work.md
  
  In KR "Everything is great":
    No work items found. This may indicate an unreported parsing error. Remove the KR if it is without work.
  [1]
  $ okra lint --short err-no-work.md
  err-no-work.md:3:No work found for "Everything is great"
  [1]

  $ cat > err-no-kr-id.md << EOF
  > # Last week
  > 
  > - Everything is great
  >   - @a (1 day)
  >   - Did everything
  > EOF
  $ okra lint err-no-kr-id.md
  [ERROR(S)]: err-no-kr-id.md
  
  In KR "Everything is great":
    No KR ID found. WIs should be in the format "This is a WI (#123)", where 123 is the WI issue ID. Legacy KRs should be in the format "This is a KR (PLAT123)", where PLAT123 is the KR ID. For WIs that don't have an ID yet, use "New WI" and for work without a WI use "No WI".
  [1]
  $ okra lint --short err-no-kr-id.md
  err-no-kr-id.md:3:No KR ID found for "Everything is great"
  [1]

  $ cat > err-no-project.md << EOF
  > - Everything is great (E1)
  >   - @a (1 day)
  >   - Did everything
  > EOF
  $ okra lint err-no-project.md
  [ERROR(S)]: err-no-project.md
  
  In KR "Everything is great": No project found (starting with '#')
  [1]
  $ okra lint --short err-no-project.md
  err-no-project.md:1:No project found for "Everything is great"
  [1]

  $ cat > err-not-all-includes.md << EOF
  > # Section
  > 
  > - Everything is great (E1)
  >   - @a (1 day)
  >   - Did everything
  > EOF
  $ okra lint --include-sections "Section A,Section B" err-not-all-includes.md
  [ERROR(S)]: err-not-all-includes.md
  
  Missing includes section: SECTION B,
  SECTION A
  [1]
  $ okra lint --include-sections "Section A,Section B" --short err-not-all-includes.md
  err-not-all-includes.md:1:Missing includes section: SECTION B, SECTION A
  [1]
