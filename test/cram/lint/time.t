Time formats
------------

Invalid time (format)

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day), eng2 (2 days)
  >   - My work
  > EOF
  [ERROR(S)]: <stdin>
  
  In KR "@eng1 (1 day), eng2 (2 days)":
    Invalid time entry found. Format is '- @eng1 (x days), @eng2 (y days)'
    where x and y must be divisible by 0.5
  [1]
  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day); @eng2 (2 days)
  >   - My work
  > EOF
  [ERROR(S)]: <stdin>
  
  In KR "@eng1 (1 day); @eng2 (2 days)":
    Invalid time entry found. Format is '- @eng1 (x days), @eng2 (y days)'
    where x and y must be divisible by 0.5
  [1]
  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (1 day) @eng2 (2 days)
  >   - My work
  > EOF
  [ERROR(S)]: <stdin>
  
  In KR "@eng1 (1 day) @eng2 (2 days)":
    Invalid time entry found. Format is '- @eng1 (x days), @eng2 (y days)'
    where x and y must be divisible by 0.5
  [1]

Invalid time (total)

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
  [ERROR(S)]: <stdin>
  
  Invalid total time found for eng1 (4.0 days).
  [1]
  $ okra lint << EOF
  > # Title
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
  [ERROR(S)]: <stdin>
  
  Invalid total time found for eng1 (10.0 days).
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
  >   - @eng1 (1.5 day)
  >   - My work
  > 
  > - This is a KR (KR124)
  >   - @eng1 (1.5 days), @eng1 (.5 day)
  >   - My work
  > EOF
  [OK]: <stdin>
