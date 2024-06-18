Types of errors
---------------

No KR ID found:

  $ okra lint --no-version-check << EOF
  > # Title
  > 
  > - This is a KR
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  File "<stdin>", line 3:
  Error: In objective "This is a KR":
         No ID found. Objectives should be in the format "This is an objective (#123)", where 123 is the objective issue ID. For objectives that don't have an ID yet, use "New KR" and for work without an objective use "No KR".
  [1]

  $ okra lint --no-version-check << EOF
  > - This is a KR (KR123)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  File "<stdin>", line 1:
  Error: In objective "This is a KR (KR123)":
         No project found (starting with '#')
  [1]

No work items found:

  $ okra lint --no-version-check << EOF
  > # Title
  > 
  > - This is a KR (KRID)
  >   - @eng1 (1 day)
  > EOF
  File "<stdin>", line 3:
  Error: In objective "This is a KR":
         No work items found. This may indicate an unreported parsing error. Remove the objective if it is without work.
  File "<stdin>", line 3:
  Error: In objective "This is a KR":
         No ID found. Objectives should be in the format "This is an objective (#123)", where 123 is the objective issue ID. For objectives that don't have an ID yet, use "New KR" and for work without an objective use "No KR".
  [1]

No time entry found:

  $ okra lint --no-version-check << EOF
  > # Title
  > 
  > - This is a KR (KR12)
  >   - My work
  >   - @eng1 (1 day)
  > EOF
  File "<stdin>", line 3:
  Error: In objective "This is a KR (KR12)":
         No time entry found. Each objective must be followed by '- @... (x days)'
  [1]

Multiple time entries:

  $ okra lint --no-version-check << EOF
  > # Title
  > 
  > - This is a KR (KR12)
  >   - @eng1 (1 day)
  >   - My work
  >   - @eng2 (2 days)
  >   - More work
  > EOF
  File "<stdin>", line 3:
  Error: In objective "This is a KR (KR12)":
         Multiple time entries found. Only one time entry should follow immediately after the objective.
  [1]

Format errors

  $ cat > err-bullet.md << EOF
  > # Title
  > 
  > - This is a KR (KRID)
  >   - @eng1 (1 day)
  >   + My work
  > EOF
  $ okra lint err-bullet.md --no-version-check
  File "err-bullet.md", line 5:
  Error: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
  [1]
  $ okra lint --short --no-version-check < err-bullet.md
  <stdin>:5: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
  [1]
  $ cat > err-space-title.md << EOF
  >  # Title
  > 
  > - This is a KR (KRID)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  $ okra lint err-space-title.md --no-version-check
  File "err-space-title.md", line 1:
  Error: Space found before title marker #. Start titles in first column.
  [1]
  $ okra lint --short err-space-title.md --no-version-check
  err-space-title.md:1: Space found before title marker #. Start titles in first column.
  [1]

  $ cat > err-space-indent.md << EOF
  > # Title
  > 
  >  - This is a KR (KRID)
  >   - @eng1 (1 day)
  >   - My work
  > EOF
  $ okra lint err-space-indent.md --no-version-check
  File "err-space-indent.md", line 3:
  Error: Single space used for indentation (' - text'). Remove or replace by 2 or more spaces.
  [1]
  $ okra lint --short err-space-indent.md --no-version-check
  err-space-indent.md:3: Single space used for indentation (' - text'). Remove or replace by 2 or more spaces.
  [1]

  $ cat > err-no-time.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - Did everything
  > EOF
  $ okra lint err-no-time.md --no-version-check
  File "err-no-time.md", line 3:
  Error: In objective "Everything is great (E1)":
         No time entry found. Each objective must be followed by '- @... (x days)'
  [1]
  $ okra lint --short err-no-time.md --no-version-check
  err-no-time.md:3: No time found in "Everything is great (E1)"
  [1]

  $ cat > err-invalid-time.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (day)
  >   - Did everything
  > EOF
  $ okra lint err-invalid-time.md --no-version-check
  File "err-invalid-time.md", line 4:
  Error: In objective "Everything is great (E1)":
         Invalid time entry "@a (day)" found. Format is '- @eng1 (x days), @eng2 (y days)'
         where x and y must be divisible by 0.5
  [1]
  $ okra lint --short err-invalid-time.md --no-version-check
  err-invalid-time.md:4: Invalid time entry "@a (day)" in "Everything is great (E1)"
  [1]

  $ cat > err-multiple-time.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (1 day)
  >   - @a (1 day)
  >   - Did everything
  > EOF
  $ okra lint err-multiple-time.md --no-version-check
  File "err-multiple-time.md", line 3:
  Error: In objective "Everything is great (E1)":
         Multiple time entries found. Only one time entry should follow immediately after the objective.
  [1]
  $ okra lint --short err-multiple-time.md --no-version-check
  err-multiple-time.md:3: Multiple time entries for "Everything is great (E1)"
  [1]

  $ cat > err-no-work.md << EOF
  > # Last week
  > 
  > - Everything is great (E1)
  >   - @a (1 day)
  > EOF
  $ okra lint err-no-work.md --no-version-check
  File "err-no-work.md", line 3:
  Error: In objective "Everything is great (E1)":
         No work items found. This may indicate an unreported parsing error. Remove the objective if it is without work.
  [1]
  $ okra lint --short err-no-work.md --no-version-check
  err-no-work.md:3: No work found for "Everything is great (E1)"
  [1]

  $ cat > err-no-kr-id.md << EOF
  > # Last week
  > 
  > - Everything is great
  >   - @a (1 day)
  >   - Did everything
  > EOF
  $ okra lint err-no-kr-id.md --no-version-check
  File "err-no-kr-id.md", line 3:
  Error: In objective "Everything is great":
         No ID found. Objectives should be in the format "This is an objective (#123)", where 123 is the objective issue ID. For objectives that don't have an ID yet, use "New KR" and for work without an objective use "No KR".
  [1]
  $ okra lint --short err-no-kr-id.md --no-version-check
  err-no-kr-id.md:3: No KR ID found for "Everything is great"
  [1]

  $ cat > err-no-project.md << EOF
  > - Everything is great (E1)
  >   - @a (1 day)
  >   - Did everything
  > EOF
  $ okra lint err-no-project.md --no-version-check
  File "err-no-project.md", line 1:
  Error: In objective "Everything is great (E1)":
         No project found (starting with '#')
  [1]
  $ okra lint --short err-no-project.md --no-version-check
  err-no-project.md:1: No project found for "Everything is great (E1)"
  [1]

  $ cat > err-not-all-includes.md << EOF
  > # Section
  > 
  > - Everything is great (E1)
  >   - @a (1 day)
  >   - Did everything
  > EOF
  $ okra lint --include-sections "Section A,Section B" err-not-all-includes.md --no-version-check
  File "err-not-all-includes.md", line 1:
  Error: Missing includes section: SECTION B, SECTION A
  [1]
  $ okra lint --include-sections "Section A,Section B" --short err-not-all-includes.md --no-version-check
  err-not-all-includes.md:1: Missing includes section: SECTION B, SECTION A
  [1]
