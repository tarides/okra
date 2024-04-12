(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Cmdliner

let get_or_error = function
  | Ok v -> v
  | Error (`Msg m) ->
      Fmt.epr "%s" m;
      exit 1

(* DB *)
let okr_db =
  let info =
    Arg.info [ "okr-db" ]
      ~doc:
        "Replace KR titles, objectives and projects with information from a \
         CSV. Requires header with columns id,title,objective,project."
  in
  Arg.value (Arg.opt (Arg.some Arg.file) None info)

(* Filters *)

let include_projects =
  let i =
    Arg.info [ "include-projects" ]
      ~doc:"If non-empty, only include this list of projects in the output."
      ~docv:"PROJECT"
  in
  Arg.(value (opt (list string) [] i))

let exclude_projects =
  let i =
    Arg.info [ "exclude-projects" ]
      ~doc:"If non-empty, exclude projects in this list from the output."
      ~docv:"PROJECT"
  in

  Arg.(value (opt (list string) [] i))

let exclude_objectives =
  let i =
    Arg.info [ "include-objectives" ]
      ~doc:"If non-empty, only include this list of objectives in the output."
      ~docv:"OBJECTIVE"
  in
  Arg.(value (opt (list string) [] i))

let include_objectives =
  let i =
    Arg.info [ "exclude-objectives" ]
      ~doc:"If non-empty, exclude objectives in this list from the output."
      ~docv:"OBJECTIVE"
  in
  Arg.(value (opt (list string) [] i))

let include_krs =
  let i =
    Arg.info [ "include-krs" ]
      ~doc:"If non-empty, only include this list of KR IDs in the output."
      ~docv:"ID"
  in
  Arg.(value (opt (list string) [] i))

let exclude_krs =
  let i =
    Arg.info [ "exclude-krs" ]
      ~doc:"If non-empty, exclude KR IDs in this list from the output."
      ~docv:"ID"
  in
  Arg.(value (opt (list string) [] i))

let include_engineers =
  let i =
    Arg.info [ "include-engineers" ]
      ~doc:"If non-empty, only include this list of engineers in the output."
      ~docv:"NAME"
  in
  Arg.(value (opt (list string) [] i))

let exclude_engineers =
  let i =
    Arg.info [ "exclude-engineers" ]
      ~doc:"If non-empty, exclude engineers in this list from the output."
      ~docv:"NAME"
  in
  Arg.(value (opt (list string) [] i))

let engineer_report =
  let info =
    Arg.info [ "engineer"; "e" ]
      ~doc:
        "Lint an engineer report. This is an alias for \
         --include-sections=\"last week\", --ignore-sections=\"\""
  in
  Arg.value (Arg.flag info)

let team_report =
  let info =
    Arg.info [ "team"; "t" ]
      ~doc:
        "Lint a team report. This is an alias for --include-sections=\"\", \
         --ignore-sections=\"OKR updates\""
  in
  Arg.value (Arg.flag info)

let filter =
  let open Let_syntax_cmdliner in
  let+ include_projects = include_projects
  and+ exclude_projects = exclude_projects
  and+ include_objectives = include_objectives
  and+ exclude_objectives = exclude_objectives
  and+ include_krs = include_krs
  and+ exclude_krs = exclude_krs
  and+ include_engineers = include_engineers
  and+ exclude_engineers = exclude_engineers in
  let include_krs = List.map Okra.Filter.kr_of_string include_krs in
  let exclude_krs = List.map Okra.Filter.kr_of_string exclude_krs in
  Okra.Filter.v ~include_projects ~exclude_projects ~include_objectives
    ~exclude_objectives ~include_krs ~exclude_krs ~include_engineers
    ~exclude_engineers ()

(* more filters.. *)

let include_categories =
  let i =
    Arg.info [ "include-categories" ]
      ~doc:
        "If non-empty, only aggregate KRs in these categories. Requires a \
         database."
  in
  Arg.(value & opt (list string) [] i)

let include_teams =
  let i =
    Arg.info [ "include-teams" ]
      ~doc:
        "If non-empty, only aggregate KRs from these teams. Requires a \
         database."
  in
  Arg.(value & opt (list string) [] i)

let include_reports =
  let i =
    Arg.info [ "include-reports" ]
      ~doc:
        "If non-empty, only aggregate KRs that are included in one of these \
         reports. Requires a database."
  in
  Arg.(value & opt (list string) [] i)

let include_sections =
  let i =
    Arg.info [ "include-sections" ]
      ~doc:
        "If non-empty, only aggregate entries under these sections - \
         everything else is ignored."
  in
  Arg.(value & opt (list string) [] i)

let ignore_sections =
  let i =
    Arg.info [ "ignore-sections" ]
      ~doc:
        "If non-empty, ignore everyhing under these sections (titles) from the \
         report"
  in
  Arg.(value & opt (list string) [ "OKR updates" ] i)

type includes = {
  include_categories : string list; (* not totally sure what these are ... *)
  include_teams : string list; (* TODO: what it is? *)
  include_reports : string list; (* TODO: what it is? *)
  include_sections : string list;
  ignore_sections : string list;
}

let includes =
  let open Let_syntax_cmdliner in
  let+ include_sections = include_sections
  and+ ignore_sections = ignore_sections
  and+ engineer_report = engineer_report
  and+ team_report = team_report
  and+ include_categories = include_categories
  and+ include_reports = include_reports
  and+ include_teams = include_teams in
  let include_sections =
    if engineer_report then [ "Last week" ] else include_sections
  in
  let ignore_sections =
    if team_report then [ "OKR Updates" ] else ignore_sections
  in
  {
    include_sections;
    ignore_sections;
    include_teams;
    include_reports;
    include_categories;
  }

(* Calendar term *)

let weeks_conv =
  let parse w =
    match Arg.conv_parser Arg.(pair ~sep:'-' int int) w with
    | Ok (x, y) -> Ok (`Range (x, y))
    | Error _ -> (
        match Arg.conv_parser Arg.int w with
        | Ok x -> Ok (`One x)
        | Error _ -> Fmt.error_msg "invalid week(s): %s" w)
  in
  let pp fs = function
    | `One x -> Format.fprintf fs "%i" x
    | `Range (x, y) -> Format.fprintf fs "%i-%i" x y
  in
  Arg.conv (parse, pp)

let weeks =
  Arg.value
  @@ Arg.opt Arg.(some weeks_conv) None
  @@ Arg.info
       ~doc:
         "The week of the year defaulting to the current week, or a range \
          specified by a start and end week (inclusive)"
       ~docv:"WEEKS" [ "w"; "weeks" ]

let month =
  Arg.value
  @@ Arg.opt Arg.(some int) None
  @@ Arg.info
       ~doc:
         "The month of the year defaulting to the current month (January = 1)"
       ~docv:"MONTH" [ "m"; "month" ]

let year =
  Arg.value
  @@ Arg.opt Arg.(some int) None
  @@ Arg.info ~doc:"The year defaulting to the current year" ~docv:"YEAR"
       [ "y"; "year" ]

let calendar : Okra.Calendar.t Term.t =
  let open Let_syntax_cmdliner in
  let module C = CalendarLib.Calendar in
  let+ weeks = weeks and+ month = month and+ year = year in
  get_or_error
  @@
  match (weeks, month) with
  | None, None -> Okra.Calendar.of_week ?year (C.now () |> C.week)
  | Some (`One week), _ -> Okra.Calendar.of_week ?year week
  | Some (`Range weeks), _ -> Okra.Calendar.of_week_range ?year weeks
  | None, Some month -> Okra.Calendar.of_month ?year month

(* Report printing configuration *)

let no_links =
  Arg.value
  @@ Arg.flag
  @@ Arg.info ~doc:"Generate shortened GitHub style urls" [ "no-links" ]

let no_names =
  Arg.value
  @@ Arg.flag
  @@ Arg.info ~doc:"Remove names of authors to the generated reports"
       [ "no-names" ]

let no_days =
  Arg.value
  @@ Arg.flag
  @@ Arg.info ~doc:"Remove days to the generated reports" [ "no-days" ]

let with_descriptions =
  Arg.value
  @@ Arg.flag
  @@ Arg.info ~doc:"Adds the body of the Issue/PR to the report"
       [ "with-descriptions" ]

type printconf = {
  links : bool;
  names : bool;
  days : bool;
  descriptions : bool;
}

let printconf =
  let open Let_syntax_cmdliner in
  let+ no_links = no_links
  and+ no_names = no_names
  and+ no_days = no_days
  and+ descriptions = with_descriptions in
  {
    links = not no_links;
    days = not no_days;
    names = not no_names;
    descriptions;
  }

let output =
  Arg.(value & opt (some string) None & info [ "o"; "output" ] ~docv:"FILE")

type t = {
  okr_db : string option;
  mutable okr_db_state : Okra.Masterdb.t option;
  filter : Okra.Filter.t;
  includes : includes;
  printconf : printconf;
  calendar : Okra.Calendar.t;
  output : string option;
  repo : string option;
  conf : Conf.t;
}

let setup () =
  let open Let_syntax_cmdliner in
  let+ style_renderer = Fmt_cli.style_renderer ()
  and+ level = Logs_cli.level () in
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  Fmt_tty.setup_std_outputs ?style_renderer ()

let conf =
  let conf_arg =
    Arg.value
    @@ Arg.opt Arg.file Conf.default_file_path
    @@ Arg.info ~doc:"Okra configuration file" ~docv:"CONF" [ "conf" ]
  in
  let load okra_file =
    match get_or_error @@ Bos.OS.File.exists (Fpath.v okra_file) with
    | false -> Conf.default
    | true -> get_or_error @@ Conf.load okra_file
  in
  Term.(const load $ conf_arg)

let repo =
  let doc = "Path to the repository containing the weekly reports." in
  let env = Cmd.Env.info "OKRA_REPO" in
  Arg.(
    value & opt (some dir) None & info [ "C"; "repo-dir" ] ~docv:"DIR" ~env ~doc)

let term =
  let open Let_syntax_cmdliner in
  let+ () = setup ()
  and+ okr_db = okr_db
  and+ filter = filter
  and+ includes = includes
  and+ printconf = printconf
  and+ conf = conf
  and+ calendar = calendar
  and+ output = output
  and+ repo = repo in
  {
    okr_db;
    filter;
    includes;
    printconf;
    calendar;
    conf;
    output;
    repo;
    okr_db_state = None;
  }

let okr_db t =
  match t.okr_db_state with
  | Some s -> Some s
  | None -> (
      let db =
        let ( or ) x y = match x with Some x -> Some x | None -> y in
        t.okr_db
        or Conf.okr_db t.conf
        or
        match t.repo with
        | Some repo -> (
            let path = Fpath.(v repo / "data" / "db.csv") in
            match Bos.OS.File.exists path with
            | Ok true -> Some (Fpath.to_string path)
            | _ -> None)
        | None -> None
      in
      match db with
      | None -> None
      | Some f ->
          let state = Okra.Masterdb.load_csv f in
          t.okr_db_state <- Some state;
          Some state)

let filter t =
  match okr_db t with
  | None -> t.filter
  | Some okr_db ->
      let additional_krs =
        Okra.Masterdb.find_krs_for_teams okr_db t.includes.include_teams
        @ Okra.Masterdb.find_krs_for_categories okr_db
            t.includes.include_categories
        @ Okra.Masterdb.find_krs_for_reports okr_db t.includes.include_reports
      in
      let kr_ids =
        List.map
          (fun f -> Okra.Filter.kr_of_string (f : Okra.Masterdb.elt_t).id)
          additional_krs
      in
      let extra_filter = Okra.Filter.v ?include_krs:(Some kr_ids) () in
      Okra.Filter.union t.filter extra_filter

let repo t =
  match t.repo with
  | Some x -> Ok x
  | None ->
      Option.to_result (Conf.admin_dir t.conf)
        ~none:
          (`Msg
            "Missing [-C] or [--repo-dir] argument, or [admin_dir] \
             configuration.")

let date t = t.calendar
let year t = Okra.Calendar.year t.calendar
let weeks t = Okra.Calendar.weeks t.calendar
let teams t = Conf.teams t.conf
let include_sections t = t.includes.include_sections
let ignore_sections t = t.includes.ignore_sections
let with_days t = t.printconf.days
let with_names t = t.printconf.names
let with_links t = t.printconf.links
let with_description t = t.printconf.descriptions
let conf t = t.conf

let output ?(input_files = []) ?(in_place = false) t =
  match t.output with
  | Some f -> open_out f
  | None -> (
      if not in_place then stdout
      else
        match input_files with
        | [] -> Fmt.invalid_arg "[-i] needs at list an input file."
        | [ f ] -> open_out f
        | _ -> Fmt.invalid_arg "[-i] needs at most a file.")

(* I/O *)

let input_files = Arg.(value & pos_all non_dir_file [] & info [] ~docv:"FILE")
let in_place = Arg.(value & flag & info [ "i"; "in-place" ])

let read_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  s

let input =
  let open Let_syntax_cmdliner in
  let+ files = input_files in
  match files with
  | [] -> Omd.of_channel stdin
  | fs ->
      let s = String.concat "\n" (List.map read_file fs) in
      Omd.of_string s
