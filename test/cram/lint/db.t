Workitems can be checked when a DB of this form is provided:

  $ mkdir -p admin/data
  $ mkdir -p admin/weekly/2023/50
  $ mkdir -p admin/weekly/2024/01

  $ cat > admin/data/db.csv << EOF
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

  $ cat > admin/weekly/2023/50/eng1.md << EOF
  > # Last week
  > 
  > - Application and Operational Metrics (#1058)
  >   - @eng1 (2 days)
  >   - Something
  > 
  > - Property-Based Testing for Multicore (#1090)
  >   - @eng1 (1 day)
  >   - Something
  > 
  > - General okra maintenance (#1115)
  >   - @eng1 (1 day)
  >   - Something
  > 
  > - Leave (#1074)
  >   - @eng1 (1 day)
  >   - off
  > EOF

  $ cat > admin/weekly/2023/50/eng2.md << EOF
  > # Last week
  > 
  > - Application and Operational Metrics (#1058)
  >   - @eng2 (2 days)
  >   - Something
  > 
  > - General okra maintenance (#1115)
  >   - @eng2 (2 days)
  >   - Something
  > 
  > - Leave (#1074)
  >   - @eng2 (1 day)
  >   - off
  > EOF

  $ okra lint -e -C admin admin/weekly/2023/50/eng1.md
  [ERROR(S)]: admin/weekly/2023/50/eng1.md
  
  In WI "Property-Based Testing for Multicore":
    Work logged on WI scheduled for 2024 Q1
  [1]

  $ okra lint -e -C admin admin/weekly/2023/50/eng2.md
  [OK]: admin/weekly/2023/50/eng2.md

  $ cat > admin/weekly/2024/01/eng1.md << EOF
  > EOF
  $ cp admin/weekly/2023/50/eng1.md admin/weekly/2024/01/eng1.md

  $ okra lint -e -C admin admin/weekly/2024/01/eng1.md
  [ERROR(S)]: admin/weekly/2024/01/eng1.md
  
  In WI "Application and Operational Metrics":
    Work logged on WI scheduled for 2023 Q4
  [1]

  $ cat > weekly.md << EOF
  > # Last week
  > 
  > - Multicore OCaml Merlin project (#1053)
  >   - @eng1 (2 days)
  >   - Some merlin
  > 
  > - Property-Based Testing for Multicore (#1090)
  >   - @eng1 (1 day)
  >   - Some multicore
  > 
  > - Invalid name (#1090)
  >   - @eng1 (1 day)
  >   - Some metrics
  > 
  > - General okra maintenance (#1115)
  >   - @eng1 (1 day)
  >   - Some okra
  > EOF

No check on WIs without the DB:

  $ okra lint -e weekly.md
  okra: [WARNING] Conflicting titles:
  - "Property-Based Testing for Multicore"
  - "Invalid name"
  [OK]: weekly.md

The DB can be passed through the [--okr-db] option:

  $ okra lint -e --okr-db admin/data/db.csv weekly.md
  okra: [WARNING] Conflicting titles:
  - "Invalid name"
  - "Property-Based Testing for Multicore"
  [OK]: weekly.md

The DB can be looked up in the [repo-dir] passed through the [-C]/[--repo-dir] option:
  $ okra lint -e -C admin weekly.md
  okra: [WARNING] Conflicting titles:
  - "Invalid name"
  - "Property-Based Testing for Multicore"
  [OK]: weekly.md
