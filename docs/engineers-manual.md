# Engineer's Manual

Table of contents
- [Generating a report](#generating-a-report)
  - [Configuration](#configuration)
- [Linting your weekly report](#linting-your-weekly-report)

## Generating a report

A weekly report based on Github activity can be generated using the `okra generate` command. Under the hood it is using [tarides/get-activity](https://github.com/tarides/get-activity) with added markdown formatting.

```sh
okra generate
```

The output looks like this:

```md
# Last Week

- Improve OKRA (#123)
  - @MagnusS (<X> days)
  - Some work

# Activity (move these items to last week)

  - Add output tests [#4](https://github.com/MagnusS/okra/issues/4)
  - Add support for including only specified KR IDs [#5](https://github.com/MagnusS/okra/issues/5)
```

To prepare the final report, the work items under `Activity` should be moved to `Last week` under the right objective and time should be added (`<X>` should be replaced with a multiple of `0.5`). Additional context can also be added here.

```md
# Last Week

- Improve OKRA (#123)
  - @MagnusS (0.5 day)
  - Add output tests [#4](https://github.com/MagnusS/okra/issues/4)
  - Add support for including only specified KR IDs [#5](https://github.com/MagnusS/okra/issues/5)
  - Meetings
```

If you need to generate a report for a previous week, you can use the following options:
- `--week XX`: to generate the report for a previous week of the same year
- `--week XX --year YY`: to generate the report for a week of a previous year

### Configuration

A list of projects you are working on can be provided in the configuration file in `~/.config/okra/conf.yaml`, for example:

```yaml
projects:
  - title: "Improve OKRA (#123)"
```

More information about the configuration file is provided [here](configuration-file.md).

## Linting your weekly report

`okra lint` can be used to check reports for errors. Having a format helps automate a lot of other tasks and the stub generation gets the report very close to being in the correct format.

If an error is found, the command will exit with a non-zero exit code.

To lint a report, run:
```sh
okra lint --engineer -C /path/to/admin/ report.md
```

Do not forget the `--engineer` (or `-e` for short) flag, otherwise your report will be considered as a team report and it will return errors (mostly because `okra` will then check every section of your report).

The expected format of engineer reports is presented [here](report-formats.md#engineer-report)
