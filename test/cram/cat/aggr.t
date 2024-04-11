Aggregate
---------

Engineer reports are aggregated correctly

  $ cat > eng1.md << EOF
  > # Last Week
  > 
  > - A Kr (KR123)
  >   - @eng1 (1.5 days)
  >   - Some work
  > 
  > - A new KR (New KR)
  >   - @eng1 (1 days)
  >   - Some work
  > 
  > - Work without a KR (No KR)
  >   - @eng1 (0.5 days)
  >   - Little bit of work
  > 
  > - Work without a KR (No WI)
  >   - @eng1 (1.0 days)
  >   - Some item of work
  > 
  > EOF

  $ cat > eng2.md << EOF
  > # Last Week
  > 
  > - A Kr (KR123)
  >   - @eng2 (1.5 days)
  >   - Some work
  > 
  > - A new KR, but different title (New KR)
  >   - @eng2 (1 days)
  >   - Some work
  > 
  > - Work without a KR (No KR)
  >   - @eng2 (1.0 days)
  >   - Small bit of work
  > 
  > EOF

  $ cat > okrs.csv << EOF
  > id,title,objective,status,schedule,lead,team,category,project
  > KR1,Actual title,Actual objective,active,,,,,Actual project
  > Kr2,Actual title 2,Actual objective,active,,,,,Actual project
  > KR3,Dropped KR,Actual objective,dropped,,,,,Actual project
  > KR123,Missing status KR,Actual objective,,,,,,Actual project
  > EOF

  $ cat eng1.md eng2.md | okra cat --engineer
  # Last Week
  
  - A Kr (KR123)
    - [@eng1](https://github.com/eng1) (1.5 days), [@eng2](https://github.com/eng2) (1.5 days)
    - Some work
    - Some work
  
  - A new KR (New KR)
    - [@eng1](https://github.com/eng1) (1 day)
    - Some work
  
  - A new KR, but different title (New KR)
    - [@eng2](https://github.com/eng2) (1 day)
    - Some work
  
  - Work without a KR (No KR)
    - [@eng1](https://github.com/eng1) (1.5 days), [@eng2](https://github.com/eng2) (1 day)
    - Little bit of work
    - Some item of work
    - Small bit of work

The output of cat passes the lint

  $ cat > eng3.md << EOF
  > # Last week
  > 
  > - My task (No KR)
  >   - @foobar (5 days)
  >   - aaa bbb ccc ddd eee fff ggg hhhh iiiii jjj kkk llll mmmm nnnn
  >     _oooo_ pppp qqqq rrrr sssss tttt uuuu vvvv xxxxxxxx yyyyy zzzzzzzz
  >     __aaaa__ bbb ccc ddd eee fff ggg hhhh iiiii jjj kkk llll mmmm nnnn
  >     ___oooo___ pppp qqqq rrrr sssss tttt uuuu vvvv xxxxxxxx yyyyy zzzzzzzz
  > EOF
  $ okra lint -e eng3.md
  [OK]: eng3.md

  $ okra cat eng3.md > aggregate.md
  $ cat aggregate.md
  # Last week
  
  - My task (No KR)
    - [@foobar](https://github.com/foobar) (5 days)
    - aaa bbb ccc ddd eee fff ggg hhhh iiiii jjj kkk llll mmmm nnnn
      _oooo_ pppp qqqq rrrr sssss tttt uuuu vvvv xxxxxxxx yyyyy zzzzzzzz
      __aaaa__ bbb ccc ddd eee fff ggg hhhh iiiii jjj kkk llll mmmm nnnn
      ___oooo___ pppp qqqq rrrr sssss tttt uuuu vvvv xxxxxxxx yyyyy zzzzzzzz
  $ okra lint aggregate.md
  [OK]: aggregate.md
