Include Sections
----------------

Missing include sections are errors, for engineer reports this is "Last Week"

  $ okra lint --engineer << EOF
  > # Projects
  > 
  > - Project1 (KR1)
  > - Project2 (KR2)
  > 
  > This is not formatted.
  > 
  > # Previous week
  > 
  > - This is a KR (KRID)
  >   - (1 day)
  >   - My work
  > 
  > # Activity
  > 
  > More unformatted text.
  > EOF
  File "<stdin>":
  Error: Missing includes section: LAST WEEK
  [1]

The include_section checker looks for all passed sections

  $ okra lint --include-sections="previous week,last week,next week" << EOF
  > # Projects
  > 
  > - Project1 (KR1)
  > - Project2 (KR2)
  > 
  > This is not formatted.
  > 
  > # Previous week
  > 
  > - This is a KR (KR1)
  >   - @bactrian (1 day)
  >   - My work
  > 
  > # Activity
  > 
  > More unformatted text.
  > EOF
  File "<stdin>":
  Error: Missing includes section: NEXT WEEK, LAST WEEK
  [1]
