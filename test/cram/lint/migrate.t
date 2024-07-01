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
  > - This objective does not exist (#32)
  >   - @eng1 (0 day)
  >   - xxx
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
  File "weekly.md", line 3:
  Error: Invalid objective: "This objective does not exist"
  File "weekly.md", line 19:
  Warning: Invalid objective:
           "General okra maintenance (#1115)" is a work-item. You should use an objective instead.
  File "weekly.md", line 15:
  Warning: Invalid objective:
           "Property-Based Testing for Multicore (#1090)" is a work-item. You should use its parent objective "Property-Based Testing for Multicore (#558)" instead.
  [1]

  $ okra lint -e -C admin weekly.md --short
  okra: [WARNING] KR ID updated from "No KR" to "#701":
  - "JSOO Effect Performance"
  - "JSOO Effect Performance"
  weekly.md:3: Invalid objective: "This objective does not exist" (not found)
  weekly.md:19: Invalid objective: "General okra maintenance (#1115)" (work-item)
  weekly.md:15: Invalid objective: "Property-Based Testing for Multicore (#1090)" (work-item), use "Property-Based Testing for Multicore (#558)" instead
  [1]

The DB can be looked up in the [admin_dir] field set int the configuration file:
  $ cat > eng1.md << EOF
  > # Last week
  > 
  > - Doesnt exist (#100000)
  >   - @eng1 (5 days)
  >   - Something
  > EOF
  $ cat > conf.yml << EOF
  > admin_dir: admin
  > EOF
  $ okra lint -e eng1.md
  [OK]: eng1.md
  $ okra lint -e --conf conf.yml eng1.md
  File "eng1.md", line 3:
  Error: Invalid objective: "Doesnt exist"
  [1]

Using a work-item instead of an objective emits a warning before Week 23 (before June 3, 2024)

  $ mkdir -p admin/weekly/2024/22
  $ cat > admin/weekly/2024/22/eng1.md << EOF
  > # Last week
  > 
  > - Property-Based Testing for Multicore (#1090)
  >   - @eng1 (5 days)
  >   - xxx
  > EOF

  $ okra lint -e -C admin admin/weekly/2024/22/eng1.md
  [OK]: admin/weekly/2024/22/eng1.md
  File "admin/weekly/2024/22/eng1.md", line 3:
  Warning: Invalid objective:
           "Property-Based Testing for Multicore (#1090)" is a work-item. You should use its parent objective "Property-Based Testing for Multicore (#558)" instead.

Using a work-item instead of an objective raises an error starting from Week 23 (from June 3, 2024)

  $ mkdir -p admin/weekly/2024/23
  $ cp admin/weekly/2024/22/eng1.md admin/weekly/2024/23

  $ okra lint -e -C admin admin/weekly/2024/23/eng1.md
  File "admin/weekly/2024/23/eng1.md", line 3:
  Error: Invalid objective:
         "Property-Based Testing for Multicore (#1090)" is a work-item. You should use its parent objective "Property-Based Testing for Multicore (#558)" instead.
  [1]
