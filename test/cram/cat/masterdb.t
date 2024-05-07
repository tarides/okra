Master DB
---------

When `--okr-db` is passed, metadata is fixed.

  $ cat > okrs.csv << EOF
  > id,title,objective,status,team,quarter
  > KR1,Actual title,Actual objective,active,team1,"Q1 2023 - Jan-Mar"
  > Kr2,Actual title 2,Actual objective,active,team1,"Q2 2021 - Apr-Jun"
  > KR3,Dropped KR,Actual objective,dropped,team2,"Q2 2024 - Apr-Jun"
  > KR5,Missing status KR,Actual objective,,team2,"Rolling"
  > EOF

  $ okra cat --okr-db=okrs.csv << EOF
  > # Wrong project
  > 
  > ## Wrong objective
  > 
  > - Wrong title (KR1)
  >   - @a (1 day)
  >   - Did all the things
  > EOF
  okra: [WARNING] Conflicting titles:
  - "Wrong title"
  - "Actual title"
  okra: [WARNING] KR Wrong title (KR1) appears in two objectives:
  - "Wrong objective"
  - "Actual objective"
  # Wrong project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things

It is possible to filter by team.

  $ okra cat --okr-db=okrs.csv --include-teams=team1 << EOF
  > # Project
  > 
  > - Actual title (KR1)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > - Dropped KR (KR3)
  >   - @a (1 day)
  >   - Did more of the things
  > EOF
  # Project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things

It is possible to filter on more than one team.

  $ okra cat --okr-db=okrs.csv --include-teams=team1,team2 << EOF
  > # Project
  > 
  > - Actual title (KR1)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > - Dropped KR (KR3)
  >   - @a (1 day)
  >   - Did more of the things
  > EOF
  # Project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things
  
  - Dropped KR (KR3)
    - @a (1 day)
    - Did more of the things

Instead of a KR ID, it is possible to put "New KR".
In that case, metadata is preserved.

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Actual title (KR1)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > # Another project
  > 
  > ## Another objective
  > 
  > - Something else (New KR)
  >   - @a (1 day)
  >   - Did all the things
  > EOF
  okra: [WARNING] KR ID not found for new KR "Something else"
  # Actual project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things
  
  # Another project
  
  ## Another objective
  
  - Something else (New KR)
    - @a (1 day)
    - Did all the things

If KR ID is "New KR", look for title in database to get real KR ID.

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Actual title (New KR)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > EOF
  # Actual project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things

If KR ID is "No KR", look for title in database to get real KR ID.

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Actual title (No KR)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > EOF
  okra: [WARNING] KR ID updated from "No KR" to "KR1":
  - "Actual title"
  - "Actual title"
  # Actual project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things

If WI ID is "No WI", look for title in database to get real WI ID.

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Actual title (No WI)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > EOF
  okra: [WARNING] KR ID updated from "No KR" to "KR1":
  - "Actual title"
  - "Actual title"
  # Actual project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things

Use same case for KR ID as in database.

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Actual title (kr1)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > - Actual title 2 (KR2)
  >   - @b (1 day)
  >   - Did more of the things
  > 
  > EOF
  # Actual project
  
  ## Actual objective
  
  - Actual title (KR1)
    - @a (1 day)
    - Did all the things
  
  - Actual title 2 (Kr2)
    - @b (1 day)
    - Did more of the things

Warn when using KRs that are not active or missing status

  $ okra cat --okr-db=okrs.csv << EOF
  > # Actual project
  > 
  > ## Actual objective
  > 
  > - Dropped KR (KR3)
  >   - @a (1 day)
  >   - Did all the things
  > 
  > - Unscheduled KR (KR4)
  >   - @b (1 day)
  >   - Did more of the things
  > 
  > - Missing status KR (KR5)
  >   - @b (1 day)
  >   - Did more of the things
  > 
  > EOF
  # Actual project
  
  ## Actual objective
  
  - Dropped KR (KR3)
    - @a (1 day)
    - Did all the things
  
  - Unscheduled KR (KR4)
    - @b (1 day)
    - Did more of the things
  
  - Missing status KR (KR5)
    - @b (1 day)
    - Did more of the things
