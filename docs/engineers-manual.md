# Engineer's Manual

Table of contents
- [Generating a report](#generating-a-report)
  - [Configuration](#configuration)
- [Linting your weekly report](#linting-your-weekly-report)
- [Rewriting workitems into objectives](#rewriting-workitems-into-objectives)

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

## Rewriting workitems into objectives

Let's suppose you have the following weekly report:

```md
# Last Week

- Workitem you have been using (#1090)
  - @jack (3 days)
  - Some work you did

- Leave
  - @jack (2 days)
```

Linting of the original file fails because we used workitems:

```sh
$ okra lint -C admin -e old_weekly.md
[ERROR(S)]: old_weekly.md
  
Invalid objective:
  "Workitem you have been using" is a work-item, you should use its parent objective "Objective you should use now" instead
[1]
```

We use `okra cat` to automatically rewrite the report using the objectives:

```sh
$ okra cat -C /path/to/admin -e old_weekly.md -o new_weekly.md
```
```md
# Last Week
  
- Property-Based Testing for Multicore (#558)
  - @jack (3 days)
  - This is a workitem with a parent objective in the DB
  
- Leave
  - @jack (2 days)
```

Linting of the produced file succeeds because we now use objectives:

```sh
$ okra lint -C admin -e new_weekly.md
[OK]: new_weekly.md
```
