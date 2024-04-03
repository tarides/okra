## unreleased

### Changed

- generate: distinguish between issue comments and PR comments (#<PR_NUMBER>, @gpetiot)

### Added

- generate: add the PR merge events to the contributions (#<PR_NUMBER>, @gpetiot)

### Fixed

- generate: take into account the end date of the specified period when filtering the activity (#<PR_NUMBER>, @gpetiot)

## 0.3.0

### Changed

- Change granularity of time to 0.5 days (#177, @punchagan @ganeshn-gh)
- Printed reports now use undercore instead of star characters for emphasis/strong styling(#180, @gpetiot)
- The weeks are now set with the option `-w`/`--weeks` and inputs are checked (#184, @gpetiot)
- Issue/PR comments are added to activity produced by `okra generate` (#185, @gpetiot)

### Added

- Multiple weeks can now be passed to `okra team aggregate` (#182, @gpetiot)
- Add new option `--user` to `okra generate` (#185, @gpetiot)

### Fixed

- Filtering options now properly apply to `okra team aggregate` (#181, @gpetiot)

## 0.2.1

### Changed

- Lower dune version to 3.2 (#169, @gpetiot)

### Removed

- Removed unused `tls` dependency (#168, @gpetiot)

## 0.2.0

### Changed

- Rename the opam packages (#164, @gpetiot)
  + `okra` is renamed `okra-lib`
  + `okra-bin` is renamed `okra`
- Depend on get-activity >= 0.2.0 (#162, @gpetiot)

## 0.1

### Added

- Add support for filtering data on team, category and report-type (@magnuss)
- Add --version option (#99, @magnuss)
- Add support for pound prefixed KRs, aka Work Items (#124, @rikusilvola)

### Changed

- Fail with an explicit error message when --repo-dir is missing (#152, @gpetiot)
- Remove not-so-useful Unicode characters from output for a11y accessibility (#151, @shindere)
- CSV parsing updates. Include new fields for reports and links. (@magnuss)
- Update cmdliner (#103, @tmcgilchrist)
- Update gitlab (#100, @tmcgilchrist)

### Fixed

- Add missing linebreaks in the project list of activity report (#148, @gpetiot)

(changes before Jan '22 not tracked)
