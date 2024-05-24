We used to report on workitems and now we use objectives.

During the transition, using workitems makes the linting fail
and the error message points to the corresponding objective.

  $ mkdir -p admin/data

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

  $ cat > admin/data/team-objectives.csv << EOF
  > "id","title","status","quarter","team","pillar","objective","funder","labels","progress"
  > "#558","Property-Based Testing for Multicore","In Progress","Q2 2024","Compiler & Language","Compiler","","","Proposal",""
  > "#677","Improve OCaml experience on Windows","Todo","Q2 2024","Multicore applications","Ecosystem","","","",""
  > "#701","JSOO Effect Performance","","Q2 2024","Compiler & Language","Compiler","","","focus/technology,level/team",""
  > EOF

  $ cat > weekly.md << EOF
  > # Last week
  > 
  > - JSOO Effect Performance (No KR)
  >   - @eng1 (1 day)
  >   - xxx
  > 
  > - Improve OCaml experience on Windows (#677)
  >   - @eng1 (1 day)
  >   - xxx
  > 
  > - Property-Based Testing for Multicore (#558)
  >   - @eng1 (1 day)
  >   - xxx
  > 
  > - General okra maintenance (#1115)
  >   - @eng1 (1 day)
  >   - xxx
  > 
  > - Property-Based Testing for Multicore (#1090)
  >   - @eng1 (1 day)
  >   - xxx
  > EOF

  $ okra lint -e -C admin weekly.md
  okra: [WARNING] KR ID updated from "No KR" to "#701":
  - "JSOO Effect Performance"
  - "JSOO Effect Performance"
  File "weekly.md":
  Error: Invalid objective:
         "General okra maintenance (#1115)" is a work-item.
         You should use an objective instead.
  File "weekly.md":
  Error: Invalid objective:
         "Property-Based Testing for Multicore (#1090)" is a work-item.
         You should use its parent objective "Property-Based Testing for Multicore (#558)" instead.
  [1]
