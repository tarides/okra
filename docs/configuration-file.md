# Okra Configuration File

You can store a `conf.yaml` file in `~/.config/okra` to provide the binary with extra information to help writing weekly reports, aggregating across directories etc.

You don't need a configuration file, but the default configuration is not really useful.

You can add a `footer` section to your configuration file which simply appends the string to the end of your report. 

```yaml
# Projects are used in weekly report generation (optional)
projects:
  - title: "Make okra great (#123)"
# Teams are used for the `okra team` subcommands.
teams:
  - name: My Team
    members:
      - name: Engineer 1
        github: eng1
      - name: Engineer 2
        github: eng2
footer: |
  # Meetings
  - A recurring meeting
```

You can also provide default work items for your projects which are particularly useful for recurring tasks (e.g. meetings). For example: 

```yaml
projects:
  - title: "Make okra great (#123)"
    items: 
      - "Meeting with @MagnusS, @samoht"
      - "Documenting the tool"
```

Sometimes you might have some recurring comments to make outside of last week's activity (perhaps meetings and the like). 
