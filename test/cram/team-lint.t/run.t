
Team Lint example with invalid reports:

  $ okra team lint -C admin/ -w 40-43 -y 2022 --conf ./conf.yml
  Team "My Team":
    + Report week 40: Not found: admin/weekly/2022/40/eng2.md
    + Report week 41: Lint error at admin/weekly/2022/41/eng2.md
                      File "admin/weekly/2022/41/eng2.md", line 4:
                      Error: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
                      
                      File "admin/weekly/2022/41/eng2.md", line 5:
                      Error: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
                      
    + Report week 42: Not found: admin/weekly/2022/42/eng2.md
    + Report week 40: Lint error at admin/weekly/2022/40/eng1.md
                      File "admin/weekly/2022/40/eng1.md", line 3:
                      Error: Invalid objective: "A KR"
                      
    + Report week 41: Lint error at admin/weekly/2022/41/eng1.md
                      File "admin/weekly/2022/41/eng1.md", line 3:
                      Error: Invalid objective: "A KR"
                      
    + Report week 42: Not found: admin/weekly/2022/42/eng1.md
  [1]

Team Lint example with only valid reports:

  $ okra team lint -C admin/ -w 43 -y 2022 --conf ./conf.yml
  [OK]: 2 reports

Team Lint example with only valid reports but warnings:

  $ okra team lint -C admin/ -w 39 -y 2022 --conf ./conf.yml
  [OK]: 2 reports
  Team "My Team":
    + Report week 39: Complete
                      File "admin/weekly/2022/39/eng2.md", line 3:
                      Warning: Invalid objective:
                               "General okra maintenance (#1115)" is a work-item. You should use an objective instead.
                      

Missing [--repo-dir] argument:

  $ okra team lint -w 40-42 -y 2022 --conf ./conf.yml
  Missing [-C] or [--repo-dir] argument, or [admin_dir] configuration.
  [1]

Wrong month:

  $ okra team lint -C admin/ -m 0 -y 2022 --conf ./conf.yml
  invalid month: 0
  [1]
  $ okra team lint -C admin/ -m 13 -y 2022 --conf ./conf.yml
  invalid month: 13
  [1]

Wrong week

  $ okra team lint -C admin/ -w 53 -y 2019 --conf ./conf.yml
  invalid week: 53
  [1]
  $ okra team lint -C admin/ -w 53 -y 2023 --conf ./conf.yml
  invalid week: 53
  [1]
  $ okra team lint -C admin/ -w 53 -y 2024 --conf ./conf.yml
  invalid week: 53
  [1]
  $ okra team lint -C admin/ -w 0 -y 2024 --conf ./conf.yml
  invalid week: 0
  [1]
  $ okra team lint -C admin/ -w 2-1 -y 2024 --conf ./conf.yml
  invalid week range: 2-1
  [1]

2020 has 53 weeks:

  $ okra team lint -C admin/ -w 53 -y 2020 --conf ./conf.yml
  Team "My Team":
    + Report week 53: Not found: admin/weekly/2020/53/eng2.md
    + Report week 53: Not found: admin/weekly/2020/53/eng1.md
  [1]
