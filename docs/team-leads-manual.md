# Team Lead's Manual

Table of contents
- [Aggregating reports](#aggregating-reports)
  - [Aggregating engineer reports](#aggregating-engineer-reports)
  - [Aggregating team reports](#aggregating-team-reports)
- [Linting reports](#linting-reports)
  - [Linting team reports](#linting-team-reports)
  - [Linting engineer reports](#linting-engineer-reports)

## Aggregating reports

### Aggregating engineer reports

`okra cat` can be used to aggregate weekly engineer or team reports in a single report. The tool will attempt to group data by project, objective and KR if these match.

The code reads data from stdin, aggregates per KR and outputs the result.

If there are unexpected warnings or errors use `okra lint` to identify and fix them.

When `--engineer` is specified, only the `Last Week` section from each report is used for input. This is useful for aggregating reports from individual engineers into a team report.

```sh
$ cat magnus.md patrick.md | okra cat --engineer
# Last Week

## Last Week

- Improve OKRA (#123)
    - @MagnusS (0.5 days), @patricoferris (0.5 days)
    - Add output tests [#4](https://github.com/MagnusS/okra/issues/4)
    - Add support for including only specified KR IDs [#5](https://github.com/MagnusS/okra/issues/5)
    - Meetings
    - Fixing mdx
```

It may be the case that you have an existing report (`agg.md`) and a new report comes in that you wish to merge into this report. You can do this with the `--append-to` flag for example `okra cat --engineer patrick.md --append-to=agg.md`.

When aggregating multiple reports `--show-time-calc` can be used to show time calculations to help with debugging:
```sh
$ cat report.md report2.md | okra cat --engineer --show-time-calc=true
[...]
- Improve OKRA (#123)
    - + @MagnusS (0.5 day)
    - + @patricoferris (0.5 day)
    - = @MagnusS (0.5 days) @patricoferris (0.5 days)
    ...
```

Several other options are available for modifying the output format, see `okra cat --help` for details. For example, only specific KRs can be included with `--include-krs=123`. Time can optionally be removed with `--show-time=false`. Sections can be ignored and removed from the final output using `--ignore-sections`.

### Aggregating team reports

If `--team` (or `-t` for short) is specified, everything is included. This is useful for aggregating reports from multiple teams (or over multiple weeks).

```sh
$ cat team1.md team2.md | okra cat --team
# MirageOS

## My objective

- Improve OKRA (#123)
    - @MagnusS (2.00 days), @patricoferris (4.00 days)
    - Fixing lint
    - More work on parser

- Other work (#124)
    - @Engineer1 (2.50 days)
    - Implemented the feature
```

## Linting reports

### Linting team reports

You can lint a team report (produced with `okra cat`, see previous section) with:
```sh
okra lint --team -C /path/to/admin/ report.md
```

### Linting engineer reports

You can lint multiple engineer reports in one go with:
```sh
okra team lint -C /path/to/admin/ -W 40-41
```

This will lint the reports of all of the team members you defined in your configuration file.

Note that you need to define one or multiple teams in your Okra configuration file for the `okra team` subcommands to function, see [more details about the configuration file](configuration-file.md).
