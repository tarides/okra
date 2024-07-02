We emit a warning if an objective is used for the wrong quarter.
This will be improved once we extract the start and end quarter of objectives.

  $ mkdir -p admin/data
  $ cat > admin/data/team-objectives.csv << EOF
  > "id","title","status","quarter","team","pillar","objective","funder","labels","progress"
  > "#558","Property-Based Testing for Multicore","In Progress","Q2 2024","Compiler & Language","Compiler","","","Proposal",""
  > "#677","Improve OCaml experience on Windows","Todo","Q2 2024","Multicore applications","Ecosystem","","","",""
  > "#701","JSOO Effect Performance","","Q2 2024","Compiler & Language","Compiler","","","focus/technology,level/team",""
  > EOF

  $ cat > eng1.md << EOF
  > # Last week
  > 
  > - Improve OCaml experience on Windows (#677)
  >   - @eng1 (1 day)
  >   - xxx
  > EOF

If the report is out of a admin/weekly repository, we cannot guess the quarter:

  $ okra lint -C admin eng1.md
  [OK]: eng1.md

If this report is for Q1, we emit a warning:

  $ mkdir -p admin/weekly/2024/01
  $ cp eng1.md admin/weekly/2024/01
  $ okra lint -C admin admin/weekly/2024/01/eng1.md
  [OK]: admin/weekly/2024/01/eng1.md
  File "admin/weekly/2024/01/eng1.md", line 3:
  Warning: In objective "Improve OCaml experience on Windows (#677)":
           Work logged on objective scheduled for 2024 Q2

If this report is for Q1, no issue:

  $ mkdir -p admin/weekly/2024/20
  $ cp eng1.md admin/weekly/2024/20
  $ okra lint -C admin admin/weekly/2024/20/eng1.md
  [OK]: admin/weekly/2024/20/eng1.md
