# A User's Guide to Okra

The executable shipped with this package is `okra` which can: 

 - Aggregate weekly reports provided they are in a particular format
 - Lint reports to check they are in the expected format
 - Generate a weekly report stub with your Github activity

What follows is some brief examples of how to use `okra` to improve the OKR reporting process.

 - [Engineers](#engineers)
   * [Generating a report](#generating-a-report)
   * [Configuring the tool for your projects](#configuring-the-tool-for-your-projects)
   * [Adding recurring items to your configuration file](#adding-recurring-items-to-your-configuration-file)
   * [Adding a footer to your report](#adding-a-footer-to-your-report)
   * [Linting your weekly report](#linting-your-weekly-report)

## Engineers

For the purposes of these [mdx](https://github.com/realworldocaml/mdx) test the tool is being run with 
the `--no-activity` flag which disables reading the Github token and sending API requests to Github. In
a real world scenario you are unlikely to want to pass this flag.

### Generating a report

<!-- $MDX dir=files -->
```sh
$ okra generate --week=37 --year=2021 --no-activity --conf=conf.simple.yaml
<USERNAME> week 37: 2021/09/13 -- 2021/09/19

# Last Week

- Make Okra, the OKR management tool (OKR1)
  - @<USERNAME> (<X> days)
  - Work Item 1

- Make a web interface for Okra (OKR2)
  - @<USERNAME> (<X> days)
  - Work Item 1

# Activity (move these items to last week)


```

This generates the skeleton stubs for your report. Without `--no-activity` this will be able to fill in your username.
Specifying `--week` and `--year` generates the report for the right week and year. In this file they are always specified
to make the output deterministic but both will default to the current week and year.

### Configuring the tool for your projects

You might have specific projects (KRs) you work on for a period of time (potentially long periods of time) and you can
supply these to Okra via the configuration file to make the stub generation even better. 

The configuration file for `okra` allows you to setup some default values and locations that should improve the user-experience of using the CLI tool. Everything in the configuration file is optional (including the file itself). The format uses [yaml](https://learnxinyminutes.com/docs/yaml/) and is structured as: 

 - `projects` can either be a `string list` of titles (e.g. `"Implement Okra (OKRA1)"`) or you can also write them as an object with two key-values, one called `title` with `string` as before and an optional one called `items` which is a `string list` of default items to fill in below each KR.
 - `locations` contains a `string list` of locations (currently this is unused).

<!-- $MDX dir=files -->
```sh
$ cat conf.simple.yaml
projects:
  - title: "Make Okra, the OKR management tool (OKR1)"
  - title: "Make a web interface for Okra (OKR2)"
$ okra generate --week=37 --year=2021  --no-activity --conf=conf.simple.yaml
<USERNAME> week 37: 2021/09/13 -- 2021/09/19

# Last Week

- Make Okra, the OKR management tool (OKR1)
  - @<USERNAME> (<X> days)
  - Work Item 1

- Make a web interface for Okra (OKR2)
  - @<USERNAME> (<X> days)
  - Work Item 1

# Activity (move these items to last week)


```

By default the path to Okra's configuration file is `~/.okra/conf.yaml`.

### Adding recurring items to your configuration file

By default the generator adds `Work Item 1` to each project to remind you there should be at least one work item. For some projects you might have some recurring work items every week (e.g. lots of meetings), you can add these to your configuration file.

<!-- $MDX dir=files -->
```sh
$ cat conf.projects.yaml
projects:
  - title: "Make Okra, the OKR management tool (OKR1)"
    items:
      - "Meetings with people"
      - "Updating the documentation"
  - title: "Make a web interface for Okra (OKR2)"
$ okra generate --week=37 --year=2021 --no-activity --conf=conf.projects.yaml
<USERNAME> week 37: 2021/09/13 -- 2021/09/19

# Last Week

- Make Okra, the OKR management tool (OKR1)
  - @<USERNAME> (<X> days)
  - Meetings with people
  - Updating the documentation

- Make a web interface for Okra (OKR2)
  - @<USERNAME> (<X> days)
  - Work Item 1

# Activity (move these items to last week)


```

### Adding a footer to your report

Sometimes you might have some recurring comments to make outside of last week's activity (perhaps meetings and the like). You can add a `footer` section to your configuration file which simply appends the string to the end of your report. 

<!-- $MDX dir=files -->
```sh
$ cat conf.footer.yaml
projects:
  - title: "Make Okra, the OKR management tool (OKR1)"
  - title: "Make a web interface for Okra (OKR2)"
footer: |
  # Meetings
  - A meeting with x, y and z
  - Another thing as well
$ okra generate --week=37 --year=2021 --no-activity --conf=conf.footer.yaml
<USERNAME> week 37: 2021/09/13 -- 2021/09/19

# Last Week

- Make Okra, the OKR management tool (OKR1)
  - @<USERNAME> (<X> days)
  - Work Item 1

- Make a web interface for Okra (OKR2)
  - @<USERNAME> (<X> days)
  - Work Item 1

# Activity (move these items to last week)




# Meetings
- A meeting with x, y and z
- Another thing as well
```

The vast space between `Activity` and `Meetings` is just an artefact of `--no-activity`. Note the `|` which tells yaml to include the newlines and any trailing spaces.

### Linting your weekly report

Having a format helps automate a lot of other tasks and the stub generation gets the report 
very close to being in the correct format. You can `lint` the format locally using `okra`.

Here's an example of a malformed report where Bactrian has forgotten to fill in the time spent 
on their first KR.

<!-- $MDX dir=files -->
```sh
$ cat bactrian.bad.md
# Projects

- Make Okra, the OKR management tool (OKR1)
- Make a web interface for Okra (OKR2)

# Last Week

- Make Okra, the OKR management tool (OKR1)
  - @bactrian (<X> days)
  - added mdx tests

- Make a web interface for Okra (OKR2)
  - @bactrian (3 days)
  - wrote some html
$ okra lint --engineer bactrian.bad.md
[ERROR(S)]: bactrian.bad.md

Invalid total time found for bactrian (3 days, expected 5 days).
[ERROR(S)]: bactrian.bad.md

In KR "Make Okra, the OKR management tool":
  No time entry found. Each KR must be followed by '- @... (x days)'
[1]
```
And here's an example of a well-formatted report:
<!-- $MDX dir=files -->
```sh
$ cat bactrian.good.md
# Projects

- Make Okra, the OKR management tool (OKR1)
- Make a web interface for Okra (OKR2)

# Last Week

- Make Okra, the OKR management tool (OKR1)
  - @bactrian (2 days)
  - added mdx tests

- Make a web interface for Okra (OKR2)
  - @bactrian (3 days)
  - wrote some html
$ okra lint --engineer bactrian.good.md
[OK]: bactrian.good.md
```

## Team Leads
### Coming soon...
