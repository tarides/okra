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
  [ERROR(S)]: <stdin>
  
  In KR "This is a KR":
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
  [ERROR(S)]: <stdin>
  
  In KR "This is a KR":
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
  [ERROR(S)]: <stdin>
  
  In KR "This is a KR":
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
  [ERROR(S)]: <stdin>
  
  In KR "This is a KR":
    Invalid time entry "@eng1 (. days)" found. Format is '- @eng1 (x days), @eng2 (y days)'
    where x and y must be divisible by 0.5
  [1]

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (. hours)
  >   - My work
  > EOF
  [ERROR(S)]: <stdin>
  
  In KR "This is a KR":
    Invalid time entry "@eng1 (. hours)" found. Format is '- @eng1 (x days), @eng2 (y days)'
    where x and y must be divisible by 0.5
  [1]

Valid time

  $ okra lint << EOF
  > # Title
  > 
  > - This is a KR (KR123)
  >   - @eng1 (.5 hours)
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
  >   - @eng1 (1.5 days), @eng1 (.5 hours)
  >   - My work
  > EOF
  okra: [WARNING] converting days metric into hours (considering 8h/day)
  okra: [WARNING] converting days metric into hours (considering 8h/day)
  [OK]: <stdin>
