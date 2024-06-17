
  $ cat admin/weekly/2024/01/eng1.md
  # Last Week
  
  - Property-Based Testing for Multicore (#558)
    - @jmid (3 days)
    - Foo foo
      - Bar:
        ```
        random seed: 107236932
        generated error fail pass / total     time test name
  
        [ ]    0    0    0    0 / 1000     0.0s STM Domain.DLS test sequential
        [00] file runtime/shared_heap.c; line 787 ### Assertion failed: Has_status_val(v, caml_global_heap_state.UNMARKED)
        /usr/bin/bash: line 1: 394730 Aborted                 (core dumped) ./focusedtest.exe -v -s 107236932
        [ ]    0    0    0    0 / 1000     0.0s STM Domain.DLS test sequential (generating)
        ```
      - Foo the foo?
  
  - Off
    - @jmid (2 days)
    - Foo
    - Bar

  $ okra lint -e admin/weekly/2024/01/eng1.md
  [OK]: admin/weekly/2024/01/eng1.md

  $ okra cat -e admin/weekly/2024/01/eng1.md > eng1-out.md
  $ cat eng1-out.md
  # Last Week
  
  - Property-Based Testing for Multicore (#558)
    - @jmid (3 days)
    - Foo foo
      - Bar:
        ```
        random seed: 107236932
  generated error fail pass / total     time test name
  
  [ ]    0    0    0    0 / 1000     0.0s STM Domain.DLS test sequential
  [00] file runtime/shared_heap.c; line 787 ### Assertion failed: Has_status_val(v, caml_global_heap_state.UNMARKED)
  /usr/bin/bash: line 1: 394730 Aborted                 (core dumped) ./focusedtest.exe -v -s 107236932
  [ ]    0    0    0    0 / 1000     0.0s STM Domain.DLS test sequential (generating)
  ```
      - Foo the foo?
  
  - Off
    - @jmid (2 days)
    - Foo
    - Bar

  $ okra lint -e eng1-out.md
  File "eng1-out.md", line 1:
  Error: Invalid total time found for jmid: Reported 3 days, expected 5 days.
  [1]
