
Team aggregate example

  $ okra team aggregate -C admin/ -w 41 -y 2022 --conf ./conf.yml
  # Last Week
  
  - A KR (KR100)
    - @eng1 (1 day)
    - Work 1
  
  - A KR (KR123)
    - @eng1 (1 day), @eng2 (1 day)
    - Work 1
    - Work 1
  
  - A KR (KR124)
    - @eng2 (1 day)
    - Work 1
  
  - Learning
    - @eng2 (1 day)
    - Learn 1
  
  - Leave
    - @eng2 (1 day)

Only select a few okrs

  $ okra team aggregate -C admin/ -w 41 -y 2022 --conf ./conf.yml --include-krs KR123,KR124
  # Last Week
  
  - A KR (KR123)
    - @eng1 (1 day), @eng2 (1 day)
    - Work 1
    - Work 1
  
  - A KR (KR124)
    - @eng2 (1 day)
    - Work 1

Exclude a few okrs

  $ okra team aggregate -C admin/ -w 41 -y 2022 --conf ./conf.yml --exclude-krs KR123,KR124
  # Last Week
  
  - A KR (KR100)
    - @eng1 (1 day)
    - Work 1
  
  - Learning
    - @eng2 (1 day)
    - Learn 1
  
  - Leave
    - @eng2 (1 day)

Multiple weeks

  $ okra team aggregate -C admin/ -w 40-41 -y 2022 --conf ./conf.yml
  # Last Week
  
  - A KR (KR100)
    - @eng1 (2 days)
    - Work 1
    - Work 1
  
  - A KR (KR123)
    - @eng1 (2 days), @eng2 (2 days)
    - Work 1
    - Work 1
    - Work 1
    - Work 1
  
  - A KR (KR124)
    - @eng2 (2 days)
    - Work 1
    - Work 1
  
  - Learning
    - @eng2 (1 day)
    - Learn 1
  
  - Leave
    - @eng1 (1 day), @eng2 (1 day)

The result of aggregate should pass the lint

  $ mkdir -p xxx/weekly/2024/10

  $ cat > xxx/weekly/2024/10/eng1.md << EOF
  > # Last week
  > 
  > - Leave (#1074)
  >   - @dummy (5 days)
  >   - xxx
  > EOF

  $ cat > xxx/weekly/2024/10/eng2.md << EOF
  > # Last week
  > 
  > - Leave (#1074)
  >   - @dummy (5 days)
  >   - xxx
  > EOF

  $ cat > db.csv << EOF
  > "id","title","status","quarter","team","pillar","objective","funder","labels","progress"
  > "Absence","Leave","Active 🏗","Rolling","Engineering","All","","","",""
  > "Learn","Learning","Active 🏗","Rolling","Engineering","All","","","",""
  > "Onboard","Onboard","Active 🏗","Rolling","Engineering","All","","","",""
  > "Meet","Meet","Active 🏗","Rolling","Engineering","All","","","",""
  > "#1053","Multicore OCaml Merlin project","Dropped ❌","Q3 2023 - Jul - Sep","Benchmark tooling","","Maintenance - Irmin","","",""
  > "#1058","Application and Operational Metrics","Complete ✅","Q4 2023 - Oct - Dec","Ci & Ops","QA","Operational Metrics for Core OCaml Services","Jane Street - Community","pillar/qa","50."
  > "#1090","Property-Based Testing for Multicore","Active 🏗","Q1 2024 - Jan - Mar","Compiler and language","Compiler","Property-Based Testing for Multicore","","pillar/compiler,team/compiler&language,Proposal","25."
  > "#1115","General okra maintenance","Draft","","","","Maintenance - internal tooling","","pillar/ecosystem,team/internal-tooling",""
  > EOF

  $ okra team aggregate --work-item-db db.csv -C xxx -y 2024 -w 10 --conf conf.yml > aggr.md

  $ cat aggr.md
  # Last week
  
  - Leave
    - @dummy (10 days)
    - xxx
    - xxx

  $ cat aggr.md | okra lint
  [OK]: <stdin>

We used to report on workitems and now we use objectives.

During the transition, using workitems makes the linting fail
and the error message points to the corresponding objective.

  $ mkdir -p xxx/data
  $ cp db.csv xxx/data
  $ cat > xxx/data/team-objectives.csv << EOF
  > "id","title","status","quarter","team","pillar","objective","funder","labels","progress"
  > "#558","Property-Based Testing for Multicore","In Progress","Q2 2024","Compiler & Language","Compiler","","","Proposal",""
  > "#677","Improve OCaml experience on Windows","Todo","Q2 2024","Multicore applications","Ecosystem","","","",""
  > "#701","JSOO Effect Performance","","Q2 2024","Compiler & Language","Compiler","","","focus/technology,level/team",""
  > EOF

This weekly is using using workitems:

  $ mkdir -p xxx/weekly/2024/01
  $ cat > xxx/weekly/2024/01/eng1.md << EOF
  > # Last Week
  > 
  > - Property-Based Testing for Multicore (#1090)
  >   - @eng1 (2 days)
  >   - This is a workitem with a parent objective in the DB
  > 
  > - Application and Operational Metrics (#1058)
  >   - @eng1 (1 day)
  >   - This is a workitem with no parent objective in the DB
  > 
  > - Leave
  >   - @eng1 (2 days)
  > EOF

This weekly is using objectives:

  $ mkdir -p xxx/weekly/2024/02
  $ cat > xxx/weekly/2024/02/eng2.md << EOF
  > # Last Week
  > 
  > - Property-Based Testing for Multicore (#558)
  >   - @eng2 (2 days)
  >   - This is an objective
  > 
  > - Improve OCaml experience on Windows (#677)
  >   - @eng2 (1 day)
  >   - This is an objective
  > 
  > - Leave
  >   - @eng2 (2 days)
  > EOF

  $ okra team aggregate -C xxx -y 2024 -w 01-02 --conf conf.yml
  # Last Week
  
  - Application and Operational Metrics (#1058)
    - @eng1 (1 day)
    - This is a workitem with no parent objective in the DB
  
  - Property-Based Testing for Multicore (#558)
    - @eng1 (2 days), @eng2 (2 days)
    - This is a workitem with a parent objective in the DB
    - This is an objective
  
  - Improve OCaml experience on Windows (#677)
    - @eng2 (1 day)
    - This is an objective
  
  - Leave
    - @eng1 (2 days), @eng2 (2 days)
