<h1 align="center">
  okra
</h1>

<p align="center">
  <strong>Aggregation tool for markdown-based activity reports.</strong>
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

`okra` can:

 - Generate a weekly report stub with your Github activity
 - Lint reports to check they are in the expected format
 - Aggregate weekly reports for multiple engineers and projects

## Getting Started

### Installation

Install opam if you don't already have it, and add [`tarides/opam-repository`](https://github.com/tarides/opam-repository) to your list of opam repositories:

Either only to the current opam switch with the command:
```sh
opam repository add tarides https://github.com/tarides/opam-repository.git
```

Or to the list of opam repositories for all opam switches with the command:
```sh
opam repository add --all tarides https://github.com/tarides/opam-repository.git
```

Update your list of packages:
```sh
opam update
```

Then you can install okra. If you had it installed previously through pinning simply run:
```sh
opam pin remove okra
```

This will both remove the pinned version and install the new one. You may also need to
`opam pin remove okra-lib` too.

If okra is not installed yet, run:
```sh
opam install okra
```

### Usage

#### For engineers

To generate your last week report:
```sh
okra gen
```

To update your report by rewriting workitems into objectives:
```sh
okra cat -C /path/to/admin -e old_weekly.md -o new_weekly.md
```

To lint your report:
```sh
okra lint -e -C /path/to/admin/ report.md
```

For more details, please refer to the [Engineer's Manual](docs/engineers-manual.md).

#### For team leads

To aggregate engineer reports:
```sh
cat magnus.md patrick.md | okra cat --engineer
```

To lint engineer reports of your team:
```sh
okra team lint -C /path/to/admin/ -w 40-41
```

To aggregate team reports:
```sh
cat team1.md team2.md | okra cat --team
```

To lint a team report:
```sh
okra lint -t -C /path/to/admin/ report.md
```

For more details, please refer to the [Team Lead's Manual](docs/team-leads-manual.md).

## Documentation

The full documentation for okra can be found [here](docs/README.md).
