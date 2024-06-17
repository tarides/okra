# Report formats

These are the formats currently recognised by the tool:
- [Engineer Report](#engineer-report)
  - [Non-engineering work time](#non-engineering-work-time)
- [Repository Report](#repository-report)
- [Team activity report](#team-activity-report)

General formatting requirements:
- Only use the character `-` for bullet points (not `+` nor `*`)
- Use space for indentation (2 preferred)

## Engineer Report

Engineer reports should be in the following format. **Only a section called `Last week` is included by default** - the rest is free form as long as it's valid markdown:

```
# Last week

- My objective (#123)
  - @engineer1 (1 day)
  - Some work

# Notes
...
```

There are a few rules:
- Each objective needs an ID (you can refer to the objective database, or use "New ID" or "No ID" if you don't know the ID)
- The total time reported must be 5 days (time off or partial work time must be reported)
- The time must be reported in multiples of 0.5 days

### Non-engineering work time

Special objectives can be used to report the following activities:

|   Category | Description  |
|:------------------|:-------------|
| Off      | Any kind of leave, holiday, or time off from work, including the two-week August company break. |
| Hack       | Time spent on Hacking Days. |
| Misc  | This includes any work that does not fall under specific objectives, including Tech Talks and All Hands. |

This information is also available at and is kept in sync with [tarides/admin GH repo README](https://github.com/tarides/admin?tab=readme-ov-file#reporting-non-engineering-work-time).

Here is an example:
```md
# Last Week

- Leave
  - @jack (1 day)

- Learning
  - @jack (1 day)
  - Studied something
```

## Repository Report

A repository report gets the PRs and issues that were "active" for a given time period for a particular set of repositories. This uses the same `generate` command as the engineer report, but if you supply `--kind=repository` this will produce a repository report. The positional arguments are then interpreted as `owner/repo` Github repositories, for example:

```sh
okra generate --kind=repository --month=10 mirage/irmin mirage/mirage
```

This will generate a single report with an Irmin and Mirage section for October (and the current year). Note, the Github API isn't as useful for repositories so the further back in time you go, the more requests have to be made to the API and the longer the report will take to produce.

By default the repository report does not contain author names, time of creation/merge or the description of the issue/PR. There are flags called `--with-names`, `--with-times` and `--with-descriptions` to toggle these respectively.

## Team activity report

The expected team report format is similar, but here every section is parsed and multiple engineers may have worked on each objective.

```md
# Project

## Objective

- My objective (#123)
  - @engineer1 (1 day), @engineer2 (2 days)
  - item 1
    - subitem
  - item 2
```

If the objective hasn't been created yet, "new KR" is recognised by the parser as a placeholder and can be used instead. If an objective of the same name is found in the database, they will be combined.

The `okra cat` command can be used to aggregate multiple engineer reports into one team report grouped by objective.
