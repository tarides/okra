# A User's Guide to Okra

The executable shipped with this package is `okra` which can: 

 - Aggregate weekly reports provided they are in a particular format
 - Lint reports to check they are in the expected format
 - Generate a weekly report stub with your Github activity

What follows is some brief examples of how to use `okra` to improve the OKR reporting process.

 - [Engineers](#engineers)
   * [Generating a report](#generating-a-report)
   * [Configuring the tool for your projects](#configuring-the-tool-for-your-projects)
   * [Linting your weekly report](#linting-your-weekly-report)

## Engineers

For the purposes of these [mdx](https://github.com/realworldocaml/mdx) test the tool is being run with 
the `--no-activity` flag which disables reading the Github token and sending API requests to Github. In
a real world scenario you are unlikely to want to pass this flag.

### Generating a report

```sh
$ okra generate --no-activity
# Projects

- TODO ADD KR (ID)

# Last Week

- TODO ADD KR (ID)
  - @<USERNAME> (<X> days)
  - Work Item 1

# Activity (move these items to last week)


```

This generate the skeleton stubs for your report. Without `--no-activity` this will be able to fill in your username.
You can also specify `--week` and `--year` to generate the report for the right week and year.

### Configuring the tool for your projects

You might have specific projects (KRs) you work on for a period of time (potentially long periods of time) and you can
supply these to Okra via the configuration file to make the stub generation even better. 

<!-- $MDX dir=files -->
```sh
$ cat conf.yaml
projects:
  - "Make Okra, the OKR management tool (OKR1)"
  - "Make a web interface for Okra (OKR2)"
$ okra generate --no-activity --conf=conf.yaml
# Projects

- Make Okra, the OKR management tool (OKR1)
- Make a web interface for Okra (OKR2)

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
Error(s) in file bactrian.bad.md:

No time entry found. Each KR must be followed by '-
.. (x days)
Error: WARNING: Time not found. Ignored P: Last Week, O: Last Week, Cnt: 1, KR: Make Okra, the OKR management tool (OKR1), KR title: Make Okra, the OKR management tool, KR id: OKR1

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
```

## Team Leads

### Coming soon...
