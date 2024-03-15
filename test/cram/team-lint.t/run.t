
Team Lint example

  $ okra team lint -C admin/ -w 40-42 -y 2022 --conf ./conf.yml
  === My Team ===
    + Engineer 1
      + Report week 40: Complete
      + Report week 41: Complete
      + Report week 42: Not found: admin//weekly/2022/42/eng1.md
    + Engineer 2
      + Report week 40: Not found: admin//weekly/2022/40/eng2.md
      + Report week 41: Lint error at admin//weekly/2022/41/eng2.md
                        Line 4: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
                        Line 5: + used as bullet point, this can confuse the parser. Only use - as bullet marker.
                        2 formatting errors found. Parsing aborted.
      + Report week 42: Not found: admin//weekly/2022/42/eng2.md

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
  === My Team ===
    + Engineer 1
      + Report week 53: Not found: admin//weekly/2020/53/eng1.md
    + Engineer 2
      + Report week 53: Not found: admin//weekly/2020/53/eng2.md
