Using an empty conf should not fail:

  $ touch empty-conf.yaml
  $ okra lint --engineer --conf empty-conf.yaml --no-version-check << EOF
  > # Last week
  > 
  > - This is a KR (KR1)
  >   - @eng1 (5 days)
  >   - My work
  > EOF
  [OK]: <stdin>

Using an invalid conf should fail:

  $ cat > invalid-conf.yaml << EOF
  > invalid
  > EOF
  $ okra lint --engineer --conf invalid-conf.yaml --no-version-check << EOF
  > # Last week
  > 
  > - This is a KR (KR1)
  >   - @eng1 (5 days)
  >   - My work
  > EOF
  Invalid configuration file invalid-conf.yaml:
    Failed building a key-value object expecting a list
  [1]

Using a valid conf should succeed:

  $ cat > valid-conf.yaml << EOF
  > admin_dir: /path/to/admin
  > EOF
  $ okra lint --engineer --conf valid-conf.yaml --no-version-check << EOF
  > # Last week
  > 
  > - This is a KR (KR1)
  >   - @eng1 (5 days)
  >   - My work
  > EOF
  [OK]: <stdin>
