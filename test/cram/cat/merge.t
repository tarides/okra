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
  > EOF

  $ cat > eng2.md << EOF
  > # Last Week
  > 
  > - A Kr (KR123)
  >   - @eng2 (1.5 days)
  >   - Some other work
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
  > EOF

  $ cat > okrs.csv << EOF
  > id,title,objective,status,team,project
  > KR123,A Kr,Actual objective,active,,Actual project
  > KR124,A Different Kr,Actual objective,active,,Actual project
  > EOF

Behaviour without a database

  $ cat eng1.md eng2.md | okra cat --engineer > agg.md && cat agg.md
  # Last Week
  
  - A Kr (KR123)
    - @eng1 (1.5 days), @eng2 (1.5 days)
    - Some work
    - Some other work

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

Behaviour with a database

  $ cat eng1.md eng2.md | okra cat --okr-db=okrs.csv --engineer > agg.md && cat agg.md
  okra: [WARNING] KR "A Kr" appears in two projects:
  - "Last Week"
  - "Actual project"
  okra: [WARNING] KR "A Kr" appears in two projects:
  - "Last Week"
  - "Actual project"
  # Actual project
  
  ## Actual objective
  
  - A Kr (KR123)
    - @eng1 (1.5 days), @eng2 (1.5 days)
    - Some work
    - Some other work

  $ okra cat --okr-db=okrs.csv --engineer --append-to=agg.md eng3.md > agg2.md && cat agg2.md
  okra: [WARNING] KR "A Kr" appears in two projects:
  - "Last Week"
  - "Actual project"
  okra: [WARNING] KR "A Different Kr" appears in two projects:
  - "Last Week"
  - "Actual project"
  # Actual project
  
  ## Actual objective
  
  - A Kr (KR123)
    - @eng1 (1.5 days), @eng2 (1.5 days), @eng3 (1.5 days)
    - Some work
    - Some other work
    - Some other, other work
  
  - A Different Kr (KR124)
    - @eng3 (1.5 days)
    - Some work
