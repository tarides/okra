Engineer reports
----------------

This is a valid one:

  $ okra lint --engineer << EOF
  > # Projects
  > 
  > - Project1 (KR1)
  > - Project2 (KR2)
  > - Project3 (#3)
  > 
  > This is not formatted.
  > 
  > # Last week
  > 
  > - This is a WI (#123)
  >   - @eng1 (1 day)
  >   - My work
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1.5 day)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (.5 day)
  >   - My work
  > 
  > - A KR yet to have an id (New KR)
  >   - @eng1 (1. day)
  >   - Some work
  > 
  > - A work without a KR (No KR)
  >   - @eng1 (1.0 day)
  >   - Some work
  > 
  > # Activity
  > 
  > More unformatted text.
  > EOF
  [OK]: <stdin>

Errors in include section are detected even if the rest is ignored.

  $ okra lint --engineer << EOF
  > # Projects
  > 
  > - Project1 (KR1)
  > - Project2 (KR2)
  > 
  > This is not formatted.
  > 
  > # Last week
  > 
  > - This is a KR (KRID)
  >   - (1 day)
  >   - My work
  > 
  > # Activity
  > 
  > More unformatted text.
  > EOF
  File "<stdin>", line 10:
  Error: In objective "This is a KR":
         No time entry found. Each objective must be followed by '- @... (x days)'
  File "<stdin>", line 10:
  Error: In objective "This is a KR":
         No ID found. Objectives should be in the format "This is an objective (#123)", where 123 is the objective issue ID. For objectives that don't have an ID yet, use "New KR" and for work without an objective use "No KR".
  [1]

Only "No KR" and "New KR" are supported for KR's without identifiers

  $ okra lint --engineer << EOF
  > # Projects
  > 
  > - Project1 (KR1)
  > - Project2 (KR2)
  > 
  > This is not formatted.
  > 
  > # Last week
  > 
  > - This is a KR (Off KR)
  >   - @eng1 (1 day)
  >   - My work
  > 
  > # Activity
  > 
  > More unformatted text.
  > EOF
  File "<stdin>":
  Error: Invalid total time found for eng1: Reported 1 day, expected 5 days.
  File "<stdin>", line 10:
  Error: In objective "This is a KR":
         No ID found. Objectives should be in the format "This is an objective (#123)", where 123 is the objective issue ID. For objectives that don't have an ID yet, use "New KR" and for work without an objective use "No KR".
  [1]

  $ okra lint --engineer << EOF
  > # Projects
  > 
  > - Project1 (KR1)
  > - Project2 (KR2)
  > 
  > This is not formatted.
  > 
  > # Last week
  > 
  > - This is a KR (KR1)
  >   - @eng1 (1.1 day)
  >   - My work
  > 
  > # Activity
  > 
  > More unformatted text.
  > EOF
  File "<stdin>", line 11:
  Error: In objective "This is a KR (KR1)":
         Invalid time entry "@eng1 (1.1 day)" found. Format is '- @eng1 (x days), @eng2 (y days)'
         where x and y must be divisible by 0.5
  [1]

  $ okra lint --engineer << EOF
  > # Projects
  > 
  > - Project1 (KR1)
  > - Project2 (KR2)
  > 
  > This is not formatted.
  > 
  > # Last week
  > 
  > - This is a KR (KR1)
  >   - @eng1 ( day)
  >   - My work
  > 
  > # Activity
  > 
  > More unformatted text.
  > EOF
  File "<stdin>", line 11:
  Error: In objective "This is a KR (KR1)":
         Invalid time entry "@eng1 ( day)" found. Format is '- @eng1 (x days), @eng2 (y days)'
         where x and y must be divisible by 0.5
  [1]

The total time reported must be 5 days

  $ okra lint --engineer << EOF
  > # Title
  > 
  > ## Last week
  > 
  > - This is a KR (KR123)
  >   - @eng1 (.5 day)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (.5 days)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (0.5 days)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (0.5 day)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (1.5 days), @eng1 (.5 day)
  >   - My work
  > EOF
  File "<stdin>":
  Error: Invalid total time found for eng1: Reported 4 days, expected 5 days.
  [1]
  $ okra lint --engineer << EOF
  > # Title
  > 
  > ## Last week
  > 
  > - This is a KR (KR123)
  >   - @eng1 (6.5 day)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (.5 days)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (0.5 days)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (0.5 day)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (1.5 days), @eng1 (.5 day)
  >   - My work
  > EOF
  File "<stdin>":
  Error: Invalid total time found for eng1: Reported 10 days, expected 5 days.
  [1]
