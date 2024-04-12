Appending
---------

Engineer reports are aggregated correctly

  $ cat > eng1.md << EOF
  > # Last Week
  > 
  > - A Kr (KR123)
  >   - @eng1 (1.5 days)
  >   - Some work
  > 
  > - Leave
  >   - @eng1 (2 days)
  > EOF

  $ cat > eng2.md << EOF
  > # Last Week
  > 
  > - A Kr (KR123)
  >   - @eng2 (1.5 days)
  >   - Some other work
  > 
  > - Leave
  >   - @eng2 (2 days)
  > 
  > EOF

  $ cat > eng3.md << EOF
  > # Last Week
  > 
  > - A Kr (KR123)
  >   - @eng3 (1.5 days)
  >   - Some other, other work
  > 
  > - A Different Kr (KR124)
  >   - @eng3 (1.5 days)
  >   - Some work
  > 
  > - Leave
  >   - @eng3 (2 days)
  > EOF

  $ cat > team-objectives.csv << EOF
  > id,title,objective,status,team,project
  > KR123,A Kr,,In Progress,,Actual project
  > KR124,A Different Kr,,In Progress,,Actual project
  > EOF

Behaviour without a database

  $ cat eng1.md eng2.md | okra cat --engineer > agg.md && cat agg.md
  # Last Week
  
  - A Kr (KR123)
    - @eng1 (1.5 days), @eng2 (1.5 days)
    - Some work
    - Some other work
  
  - Leave
    - @eng1 (2 days), @eng2 (2 days)

  $ okra cat --engineer --append-to=agg.md eng3.md > agg2.md && cat agg2.md
  # Last Week
  
  - A Kr (KR123)
    - @eng1 (1.5 days), @eng2 (1.5 days), @eng3 (1.5 days)
    - Some work
    - Some other work
    - Some other, other work
  
  - A Different Kr (KR124)
    - @eng3 (1.5 days)
    - Some work
  
  - Leave
    - @eng1 (2 days), @eng2 (2 days), @eng3 (2 days)

Behaviour with a database

  $ cat eng1.md eng2.md | okra cat --objective-db=team-objectives.csv --engineer > agg.md && cat agg.md
  # Last Week
  
  - A Kr (KR123)
    - @eng1 (1.5 days), @eng2 (1.5 days)
    - Some work
    - Some other work
  
  - Leave
    - @eng1 (2 days), @eng2 (2 days)

  $ okra cat --objective-db=team-objectives.csv --engineer --append-to=agg.md eng3.md > agg2.md && cat agg2.md
  # Last Week
  
  - A Kr (KR123)
    - @eng1 (1.5 days), @eng2 (1.5 days), @eng3 (1.5 days)
    - Some work
    - Some other work
    - Some other, other work
  
  - A Different Kr (KR124)
    - @eng3 (1.5 days)
    - Some work
  
  - Leave
    - @eng1 (2 days), @eng2 (2 days), @eng3 (2 days)
