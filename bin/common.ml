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
let work_item_db =
  let info =
    Arg.info [ "work-item-db" ]
      ~doc:
        "Replace work item titles, objectives and projects with information \
         from a CSV. Requires header with columns id,title,objective,project."
  in
  Arg.value (Arg.opt (Arg.some Arg.file) None info)

let objective_db =
  let info =
    Arg.info [ "objective-db" ]
      ~doc:
        "Replace objective titles, objectives and projects with information \
         from a CSV. Requires header with columns id,title,objective,project."
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

let include_objectives =
  let i =
    Arg.info [ "include-objectives" ]
      ~doc:"If non-empty, only include this list of objectives in the output."
      ~docv:"OBJECTIVE"
  in
  Arg.(value (opt (list string) [] i))

let exclude_objectives =
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
         --ignore-sections=\"\""
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

let include_teams =
  let i =
    Arg.info [ "include-teams" ]
      ~doc:
        "If non-empty, only aggregate KRs from these teams. Requires a \
         database."
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
  Arg.(value & opt (list string) [] i)

type includes = {
  include_teams : string list;
  include_sections : string list;
  ignore_sections : string list;
}

let includes =
  let open Let_syntax_cmdliner in
  let+ include_sections = include_sections
  and+ ignore_sections = ignore_sections
  and+ include_teams = include_teams in
  { include_sections; ignore_sections; include_teams }

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
  work_item_db : string option;
  objective_db : string option;
  mutable okr_db_state : Okra.Masterdb.t option;
  filter : Okra.Filter.t;
  includes : includes;
  printconf : printconf;
  calendar : Okra.Calendar.t;
  output : string option;
  repo : string option;
  conf : Conf.t;
  check_time : Okra.Time.t option;
  report_kind : Okra.Parser.report_kind option;
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
  and+ work_item_db = work_item_db
  and+ objective_db = objective_db
  and+ filter = filter
  and+ includes = includes
  and+ printconf = printconf
  and+ conf = conf
  and+ calendar = calendar
  and+ output = output
  and+ repo = repo
  and+ team_report = team_report
  and+ engineer_report = engineer_report in
  let report_kind =
    match (team_report, engineer_report) with
    | true, true ->
        Fmt.invalid_arg "[--engineer] and [--team] are mutually exclusive."
    | true, false -> Some Okra.Parser.Team
    | false, true -> Some Okra.Parser.Engineer
    | false, false -> None
  in
  let check_time = Option.map Okra.Time.days (Conf.work_days_in_a_week conf) in
  {
    work_item_db;
    objective_db;
    filter;
    includes;
    printconf;
    calendar;
    conf;
    output;
    repo;
    okr_db_state = None;
    check_time;
    report_kind;
  }

let repo t =
  match t.repo with
  | Some x -> Ok x
  | None ->
      Option.to_result (Conf.admin_dir t.conf)
        ~none:
          (`Msg
            "Missing [-C] or [--repo-dir] argument, or [admin_dir] \
             configuration.")

let db_path t ~from_cmdline ~from_conf ~from_file:fname =
  let ( or ) x y = match x with Some x -> Some x | None -> y in
  from_cmdline
  or from_conf t.conf
  or
  match repo t with
  | Ok repo -> (
      let path = Fpath.(v repo / "data" / fname) in
      match Bos.OS.File.exists path with
      | Ok true -> Some (Fpath.to_string path)
      | _ -> None)
  | Error _ -> None

let okr_db t =
  match t.okr_db_state with
  | Some s -> Some s
  | None -> (
      match
        db_path t ~from_cmdline:t.objective_db ~from_conf:Conf.objective_db
          ~from_file:"team-objectives.csv"
      with
      | Some objective_db ->
          let objective_db =
            Okra.Masterdb.Objective.load_csv objective_db |> get_or_error
          in
          let work_item_db =
            match
              db_path t ~from_cmdline:t.work_item_db
                ~from_conf:Conf.work_item_db ~from_file:"db.csv"
            with
            | None -> None
            | Some f -> Some (Okra.Masterdb.Work_item.load_csv f |> get_or_error)
          in
          let okr_db = { Okra.Masterdb.objective_db; work_item_db } in
          t.okr_db_state <- Some okr_db;
          Some okr_db
      | None -> None)

let filter t =
  match okr_db t with
  | None -> t.filter
  | Some okr_db ->
      let additional_krs =
        Okra.Masterdb.Objective.find_krs_for_teams okr_db.objective_db
          t.includes.include_teams
      in
      let kr_ids =
        List.map
          (fun f ->
            Okra.Filter.kr_of_string (f : Okra.Masterdb.Objective.elt_t).id)
          additional_krs
      in
      let extra_filter = Okra.Filter.v ?include_krs:(Some kr_ids) () in
      Okra.Filter.union t.filter extra_filter

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
let check_time t = t.check_time
let report_kind t = t.report_kind

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
