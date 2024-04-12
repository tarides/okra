<h1 align="center">
  okra
</h1>

<p align="center">
  <strong>OKR report aggregation tool.</strong>
</p>

<p align="center">
  <!--
  <a href="https://ocaml.ci.dev/github/tarides/okra">
    <img src="https://img.shields.io/endpoint?url=https://ocaml.ci.dev/badge/tarides/okra/main&logo=ocaml" alt="OCaml-CI Build Status" />
  </a>
  -->

  <a href="https://github.com/tarides/okra/actions/workflows/build.yml">
    <img src="https://github.com/tarides/okra/actions/workflows/build.yml/badge.svg?branch=main" alt="Build Status" />
  </a>
</p>

Prototype aggregation tool and library for markdown-based OKR reports. This is work in progress.

The tool currently supports generating weekly report stubs based on Github activity (`okra generate --week=xx`), grouping data from reports per KR (`okra cat ...`) and linting existing reports to catch formatting errors (`okra lint ..`).

Each command is described in more detail below.

## Installation

Install opam if you don't already have it, and add [`tarides/opam-repository`](https://github.com/tarides/opam-repository) to your list of opam repositories:

Either only to the current opam switch with the command

```
opam repository add tarides https://github.com/tarides/opam-repository.git
```

Or to the list of opam repositories for all opam switches with the command:
```
opam repository add --all tarides https://github.com/tarides/opam-repository.git
```

Update your list of packages:
```
opam update
```

Then you can install okra. If you had it installed previously  through pinning simply run:

```
opam pin remove okra
```

(This will both remove the pinned version and install the new one.)

If okra is not installed yet, run:

```
opam install okra
```

## Generating weekly engineer reports

A weekly report based on Github activity can be generated using the `okra generate` command. Under the hood it is using [tarides/get-activity](https://github.com/tarides/get-activity) with added markdown formatting.

The output looks like this:

```
$ okra generate --week=30
# Projects

- Improve OKRA (OKRA1)

# Last Week

- Improve OKRA (OKRA1)
  - @MagnusS (<X> days)
  - Work Item 1

# Activity (move these items to last week)

  - Add output tests [#4](https://github.com/MagnusS/okra/issues/4)
  - Add support for including only specified KR IDs [#5](https://github.com/MagnusS/okra/issues/5)
```

To prepare the final report, the work items under `Activity` should be moved to `Last week` under the right KR and time should be added. Additional information can also be added here.

```
# Projects

- Improve OKRA (OKRA1)

# Last Week

- Improve OKRA (OKRA1)
  - @MagnusS (0.5 day)
  - Add output tests [#4](https://github.com/MagnusS/okra/issues/4)
  - Add support for including only specified KR IDs [#5](https://github.com/MagnusS/okra/issues/5)
  - Meetings
```

You can also check that the final formatting is correct before submitting the report:

```
$ okra lint --engineer report.md
```

### Configuration

To generate reports this subcommand requires a Github token stored in `~/.github/github-activity-token` to be able to access your activity. New tokens can be added in your Github profile [here](https://github.com/settings/tokens). The token should only have read access - if you just want to show public activity it doesn't need access to any additional scopes. For more details, see [tarides/get-activity](https://github.com/tarides/get-activity).

If you get an HTTPS error while downloading the Github activity, TLS support is probably not compiled into cohttp/conduit. `opam install tls` should fix this.

A list of projects you are working on can be provided in the configuration file in `~/.config/okra/conf.yaml`, for example:

```
projects:
  - title: "Improve OKRA (OKRA1)"
```

More information is provided at the bottom of the README.

## Aggregating reports

`okra cat` can be used to aggregate weekly engineer or team reports in a single report. The tool will attempt to group data by project, objective and KR if these match.

The code reads data from stdin, aggregates per KR and outputs the result.

If there are unexpected warnings or errors use `okra lint` to identify and fix them.

When `--engineer` is specified, only the `Last Week` section from each report is used for input. This is useful for aggregating reports from individual engineers into a team report.

```
$ cat magnus.md patrick.md | okra cat --engineer
# Last Week

## Last Week

- Improve OKRA (OKRA1)
    - @MagnusS (0.50 days), @patricoferris (0.50 days)
    - Add output tests [#4](https://github.com/MagnusS/okra/issues/4)
    - Add support for including only specified KR IDs [#5](https://github.com/MagnusS/okra/issues/5)
    - Meetings
    - Fixing mdx
```

It may be the case that you have an existing report (`agg.md`) and a new report comes in that you wish to merge into this report. You can do this with the `--append-to` flag for example `okra cat --engineer patrick.md --append-to=agg.md`.

If `--team` is specified, everything is included. This is useful for aggregating reports from multiple teams (or over multiple weeks).

```
$ cat team1.md team2.md | okra cat --team
# MirageOS

## My objective

- Improve OKRA (OKRA1)
    - @MagnusS (2.00 days), @patricoferris (4.00 days)
    - Fixing lint
    - More work on parser

- Other work (KR123)
    - @Engineer1 (2.50 days)
    - Implemented the feature
```

When aggregating multiple reports `--show-time-calc` can be used to show time calculations to help with debugging:
```
$ cat report.md report2.md | okra cat --engineer --show-time-calc=true
[...]
- Improve OKRA (OKRA1)
    - + @MagnusS (0.5 day)
    - + @patricoferris (0.5 day)
    - = @MagnusS (0.50 days) @patricoferris (0.50 days)
    ...
```


Several other options are available for modifying the output format, see `okra cat --help` for details. For example, only specific KRs can be included with `--include-krs=KR123`. Time can optionally be removed with `--show-time=false`. Sections can be ignored and removed from the final output using `--ignore-sections`.

## Linting reports

`okra lint` can be used to check reports for errors. The linter will run in two phases, first checking for formatting errors then by parsing the markdown looking for inconsistencies.

For formatting errors, each error is listed with a line number and explanation. When a parsing error is found the tool will terminate and display the error with a possible solution. If an error is found, the command will exit with a non-zero exit code.

Formatting errors will look like this:
```
$ okra lint --engineer report.md
Error(s) in file report.md:

Line 7: * used as bullet point, this can confuse the parser. Only use - as bullet marker.
1 formatting errors found. Parsing aborted.
```

When encountering parsing errors:

```
$ okra lint --engineer report.md
Error(s) in file report.md:

Invalid time entry found. Format is '- @eng1 (x days), @eng2 (x days)'
Error: Time record is invalid: (MagnusS 0.5 day)
```

We currently support two types of reports; team report and engineer report. These can be specified with `--team` and `--engineer` respectively. The main difference is which sections are included or ignored in the report (see `okra lint --help` for details).

```
$ okra lint --engineer report.md
```

or 

```
$ okra lint --team report.md
```

You can also lint multiple engineer reports in one go with the `okra team lint` command.

For instance, running:

```
$ okra team lint -C admin/ -W 40.41
```

Will lint the reports of all of the team members you defined in your configuration file.

Note that you need to define one or multiple teams in your Okra configuration file for the `okra team` subcommands to function.

## Report formats

These are the formats currently recognised by the tool.

General formatting requirements:
- Only use '-' for bullet points
- Use space for indentation (2 preferred)

### Engineer Report

Engineer reports should be in the following format. Only a section called `Last week` is included by default - the rest is free form as long as it's valid markdown:

```
# Projects

- My KR (KR123)

# Last week

- My KR (KR123)
  - @engineer1 (1 day)
  - Work item 1

# Notes
...
```

The `okra generate --week=xx` command can be used to generate a stub for this report based on your Github activity and a template. To verify formatting, use `okra lint --engineer`.

There are multiple ways to specify the time-frame you are interested in with the following priority order:

 - Only running `okra generate` will use the current `week` and `year`.
 - Running `okra generate --week=X` will use the `week` with the current `year`.
 - You can specify a range of weeks using the `weeks` argument, so `okra generate --weeks=33-39` will get all of your activity from the start of week 33 to the **end** of week 39.
 - Finally, you can also specify `--month=X` to generate a report from the first to the last day of a particular month (with January being `1`). 

There is also a `--include-repositories` argument where you can specify a comma-separated list of Github repositories. Each repository will have all of its PRs filtered to find the ones you merged. Most people probably don't need to use this feature, it's only useful for people who spend time on other people's PRs and don't explicitly approve the PR using the Github web UI.

These all apply to generating a repository report too which is next.

### Repository Report

A repository report gets the PRs and issues that were "active" for a given time period for a particular set of repositories. This uses the same `generate` command as the engineer report, but if you supply `--kind=repository` this will produce a repository report. The positional arguments are then interpreted as `owner/repo` Github repositories, for example:

```
okra generate --kind=repository --month=10 mirage/irmin mirage/mirage
```

This will generate a single report with an Irmin and Mirage section for October (and the current year). Note, the Github API isn't as useful for repositories so the further back in time you go, the more requests have to be made to the API and the long the report will take to produce.

By default the repository report does not contain author names, time of creation/merge or the description of the issue/PR. There are flags called `--with-names`, `--with-times` and `--with-descriptions` to toggle these respectively.

### Team activity report

The expected team report format is similar, but here every section is parsed and multiple engineers may have worked on each KR.

```
# Project

## Objective

- My KR (KR ID)
  - @engineer1 (1 day), @engineer2 (2 days)
  - work item 1
    - subitem
  - work item 2
```

KR ID should consist of characters followed by a number (e.g. "KR123").

If the KR doesn't have a KR ID yet, "new KR" is recognised by the parser as a placeholder and can be used instead. If a KR with the same name is found with a proper KR ID later they will be combined.

The `okra cat` command can be used to aggregate multiple engineer reports into one team report grouped by KR.

## Okra Configuration File

You can store a `conf.yaml` file in `~/.config/okra` to provide the binary with extra information to help writing weekly reports, aggregating across directories etc. You don't need a configuration file, there is a default one (but it isn't particularly useful).

```yaml
# Projects are used in weekly report generation (optional)
projects:
  - title: "Make okra great (Plat123)"
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
  - title: "Make okra great (Plat123)"
    items: 
      - "Meeting with @MagnusS, @samoht"
      - "Documenting the tool"
```

There are [mdx tests](test/bin/README.md) which show the output from such a configuration file and explain in detail what the different parts do.

## Vim integration

### `okra lint` as a syntastic checker

`okra lint` can be used as a checker for [syntastic]. When this is set up, `okra
lint` are displayed with location info (or available in the quickfix list).

To do so, set up this repository as a vim plugin. For example with [vim-plug],
add this line to the list of plugins in `~/.vimrc`:

```vim
Plug 'MagnusS/okra'
```

By default, checkers are not active so a manual `:SyntasticCheck okra` is
necessary to trigger the check. Having the check by default for all markdown
files is not desirable because most markdown is not understood by `okra`. But it
is possible to enable it in certain directories. This can be done by adding the
following line in `~/.vimrc`:

```vim
autocmd BufRead,BufNewFile ~/src/weekly-reports/* let g:syntastic_markdown_checkers = ['okra']
```

[syntastic]: https://github.com/vim-syntastic/syntastic
[vim-plug]: https://github.com/junegunn/vim-plug

### OKR name completion

While not strictly related to `okra` it can be handy to complete KR names from a
fixed list.

To do so it is possible to rely on the `fzf.vim` plugin:

```vim
" In the plugin section
Plug 'junegunn/fzf.vim'

" Later
inoremap <expr> <c-x><c-k> fzf#vim#complete('cat /path/to/.okrs')
```

And create a file at `/path/to/.okrs` with one line per KR, for example:

```
- libsomething supports Windows (Some1)
- program P is integrated with dune (P12)
```

Now when in insert mode, <kbd>Ctrl</kbd>+<kbd>X</kbd> followed by
<kbd>Ctrl</kbd>+<kbd>K</kbd> will fuzzy complete lines in that file.
