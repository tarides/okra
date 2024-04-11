
Team aggregate example

  $ okra team aggregate -C admin/ -w 41 -y 2022 --conf ./conf.yml
  # Last Week
  
  - A KR (KR100)
    - [@eng1](https://github.com/eng1) (1 day)
    - Work 1
  
  - A KR (KR123)
    - [@eng1](https://github.com/eng1) (1 day), [@eng2](https://github.com/eng2) (1 day)
    - Work 1
    - Work 1
  
  - A KR (KR124)
    - [@eng2](https://github.com/eng2) (1 day)
    - Work 1

Only select a few okrs

  $ okra team aggregate -C admin/ -w 41 -y 2022 --conf ./conf.yml --include-krs KR123,KR124
  # Last Week
  
  - A KR (KR123)
    - [@eng1](https://github.com/eng1) (1 day), [@eng2](https://github.com/eng2) (1 day)
    - Work 1
    - Work 1
  
  - A KR (KR124)
    - [@eng2](https://github.com/eng2) (1 day)
    - Work 1

Exclude a few okrs

  $ okra team aggregate -C admin/ -w 41 -y 2022 --conf ./conf.yml --exclude-krs KR123,KR124
  # Last Week
  
  - A KR (KR100)
    - [@eng1](https://github.com/eng1) (1 day)
    - Work 1

Multiple weeks

  $ okra team aggregate -C admin/ -w 40-41 -y 2022 --conf ./conf.yml
  # Last Week
  
  - A KR (KR100)
    - [@eng1](https://github.com/eng1) (2 days)
    - Work 1
    - Work 1
  
  - A KR (KR123)
    - [@eng1](https://github.com/eng1) (2 days), [@eng2](https://github.com/eng2) (2 days)
    - Work 1
    - Work 1
    - Work 1
    - Work 1
  
  - A KR (KR124)
    - [@eng2](https://github.com/eng2) (2 days)
    - Work 1
    - Work 1
