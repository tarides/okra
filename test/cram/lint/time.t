Time formats
------------

Invalid time

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day), eng2 (2 days)
  >   - My work
  > EOF
  File "<stdin>", line 4:
  Error: In objective "This is a KR (KR123)":
         Invalid time entry "@eng1 (1 day), eng2 (2 days)" found. Format is '- @eng1 (x days), @eng2 (y days)'
         where x and y must be divisible by 0.5
  [1]
  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day); @eng2 (2 days)
  >   - My work
  > EOF
  File "<stdin>", line 4:
  Error: In objective "This is a KR (KR123)":
         Invalid time entry "@eng1 (1 day); @eng2 (2 days)" found. Format is '- @eng1 (x days), @eng2 (y days)'
         where x and y must be divisible by 0.5
  [1]
  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day) @eng2 (2 days)
  >   - My work
  > EOF
  File "<stdin>", line 4:
  Error: In objective "This is a KR (KR123)":
         Invalid time entry "@eng1 (1 day) @eng2 (2 days)" found. Format is '- @eng1 (x days), @eng2 (y days)'
         where x and y must be divisible by 0.5
  [1]
  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (. days)
  >   - My work
  > EOF
  File "<stdin>", line 4:
  Error: In objective "This is a KR (KR123)":
         Invalid time entry "@eng1 (. days)" found. Format is '- @eng1 (x days), @eng2 (y days)'
         where x and y must be divisible by 0.5
  [1]

Valid time

  $ okra lint << EOF
  > # Title
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
  [OK]: <stdin>

Using the configuration file to change the default number of working days.

  $ cat > valid-conf.yaml << EOF
  > work_days_in_a_week: 1.5
  > EOF
  $ okra lint --engineer --conf valid-conf.yaml << EOF
  > # Last week
  > 
  > - This is a KR (KR1)
  >   - @eng1 (1.5 days)
  >   - My work
  > EOF
  [OK]: <stdin>
  $ okra lint --engineer --conf valid-conf.yaml << EOF
  > # Last week
  > 
  > - This is a KR (KR1)
  >   - @eng1 (0.5 days)
  >   - My work
  > EOF
  File "<stdin>":
  Error: Invalid total time found for eng1 (reported 0.5 days, expected 1.5 days).
  [1]
