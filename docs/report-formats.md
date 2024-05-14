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

Engineer reports should be in the following format. Only a section called `Last week` is included by default - the rest is free form as long as it's valid markdown:

```
# Last week

- My workitem (#123)
  - @engineer1 (1 day)
  - Work item 1

# Notes
...
```

There are a few rules:
- Each workitem needs an ID (you can refer to the workitem database, or use "New ID" or "No ID" if you don't know the ID)
- The total time reported must be 5 days (time off or partial work time must be reported)
- The time must be reported in multiples of 0.5 days

### Non-engineering work time

Special workitems can be used to report the following activities:
- Community: Maintenance work that does not fall into any maintenance proposals. Discussion on discuss, discord, slack.
- Hack: Hacking Days
- Learning: Attending company-sponsored training, attending Conferences, learning, Mirage/OCaml retreats
- Leave: Any kind of leaves, holidays, time off from work, including the 2-week August company break
- Management: TL and EM work other than meetings
- Meet: Meetings, Offsite
- Onboard: Onboarding time

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

The expected team report format is similar, but here every section is parsed and multiple engineers may have worked on each workitem.

```
# Project

## Objective

- My workitem (#123)
  - @engineer1 (1 day), @engineer2 (2 days)
  - work item 1
    - subitem
  - work item 2
```

If the workitem hasn't been created yet, "new KR" is recognised by the parser as a placeholder and can be used instead. If a workitem of the same name is found in the database, they will be combined.

The `okra cat` command can be used to aggregate multiple engineer reports into one team report grouped by workitem.
