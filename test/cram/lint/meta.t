Meta workitems are not checked in the database:
- the IDs in db.csv are incorrect;
- when we migrate to objectives there won't be dedicated meta objectives.

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

  $ cat > weekly.md << EOF
  > # Last week
  > 
  > - Leave
  >   - @eng1 (1 day)
  > 
  > - Hack
  >   - @eng1 (1 day)
  >   - xxx
  > 
  > - Off-objective
  >   - @eng1 (3 days)
  >   - xxx
  > EOF

  $ okra lint -e -C admin/ weekly.md --no-version-check
  [OK]: weekly.md
