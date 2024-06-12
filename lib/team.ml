(*
 * Copyright (c) 2022 Thibaut Mattio <thibaut.mattio@gmail.com>
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

module Member = struct
  type t = { name : string; github : string }

  let make ~name ~github = { name; github }
  let name { name; _ } = name
  let github { github; _ } = github
end

type t = { name : string; members : Member.t list }

let make ~name ~members = { name; members }
let name { name; _ } = name
let members { members; _ } = members

type file_status =
  | Complete of Lint.Warning.t list
  | Not_found
  | Not_lint of [ Lint.Warning.t | Lint.Error.t ] list

type week_report = { week : int; filename : string; status : file_status }

type user_report = {
  member : Member.t;
  week_reports :
    [ `Complete of int * week_report list | `Incomplete of week_report list ];
}

type team_report = {
  team : t;
  user_reports :
    [ `Complete of int * week_report list | `Incomplete of week_report list ];
}

type lint_report =
  [ `Complete of int * (t * week_report list) list
  | `Incomplete of (t * week_report list) list ]

let file_path ~admin_dir ~week ~year ~engineer_name =
  let open Fpath in
  v admin_dir
  / "weekly"
  / Fmt.str "%4d" year
  / Fmt.str "%02i" week
  / (engineer_name ^ ".md")
  |> to_string

let lint_member_week ?okr_db ~admin_dir member ~week ~year : week_report =
  let fname =
    file_path ~admin_dir ~week ~year ~engineer_name:(Member.github member)
  in
  let status =
    match Sys.file_exists fname with
    | false -> Not_found
    | true -> (
        let ic = open_in fname in
        (* We lint week-by-week so we use the default options of the [engineer]
           mode. *)
        match Lint.lint ?okr_db ic ~report_kind:Engineer ~filename:fname with
        | Ok () -> Complete []
        | Error lx ->
            let err, warn =
              List.fold_left
                (fun (errors, warnings) -> function
                  | #Lint.Error.t as e -> (e :: errors, warnings)
                  | #Lint.Warning.t as w -> (errors, w :: warnings))
                ([], []) lx
            in
            if err = [] then Complete warn else Not_lint lx)
  in
  { week; filename = fname; status }

let lint_member_weeks ?okr_db ~admin_dir ~year member =
  List.map (fun week -> lint_member_week ?okr_db ~year ~week ~admin_dir member)

let lint_member ?okr_db ~admin_dir ~year weeks member : user_report =
  let week_reports = lint_member_weeks ?okr_db ~year ~admin_dir member weeks in
  let week_reports =
    List.fold_left
      (fun acc wr ->
        match acc with
        | `Incomplete errs -> (
            match wr.status with
            | Complete [] -> `Incomplete errs
            | _ -> `Incomplete (wr :: errs))
        | `Complete (total, wrs) -> (
            match wr.status with
            | Complete [] -> `Complete (total + 1, wrs)
            | Complete _ -> `Complete (total + 1, wr :: wrs)
            | _ -> `Incomplete (wr :: wrs)))
      (`Complete (0, []))
      week_reports
  in
  { member; week_reports }

let lint_members ?okr_db ~admin_dir ~year ~weeks =
  List.map (lint_member ?okr_db ~year ~admin_dir weeks)

let lint_team ?okr_db ~year ~admin_dir ~weeks team : team_report =
  let user_reports =
    lint_members ?okr_db ~year ~admin_dir ~weeks (members team)
  in
  let user_reports =
    List.fold_left
      (fun acc ur ->
        match acc with
        | `Incomplete wrs -> (
            match ur.week_reports with
            | `Complete (_, []) -> `Incomplete wrs
            | `Complete (_, wrs') -> `Incomplete (List.rev_append wrs' wrs)
            | `Incomplete wrs' -> `Incomplete (List.rev_append wrs' wrs))
        | `Complete (total, wrs) -> (
            match ur.week_reports with
            | `Complete (total', []) -> `Complete (total + total', wrs)
            | `Complete (total', wrs') ->
                `Complete (total + total', List.rev_append wrs' wrs)
            | `Incomplete wrs' -> `Incomplete (List.rev_append wrs' wrs)))
      (`Complete (0, []))
      user_reports
  in
  { team; user_reports }

let lint ?okr_db admin_dir ~year ~weeks teams : lint_report =
  let team_reports =
    List.map (lint_team ?okr_db ~year ~admin_dir ~weeks) teams
  in
  List.fold_left
    (fun acc ur ->
      match acc with
      | `Incomplete wrs -> (
          match ur.user_reports with
          | `Complete (_, []) -> `Incomplete wrs
          | `Complete (_, wrs') -> `Incomplete ((ur.team, wrs') :: wrs)
          | `Incomplete wrs' -> `Incomplete ((ur.team, wrs') :: wrs))
      | `Complete (total, wrs) -> (
          match ur.user_reports with
          | `Complete (total', []) -> `Complete (total + total', wrs)
          | `Complete (total', wrs') ->
              `Complete (total + total', (ur.team, wrs') :: wrs)
          | `Incomplete wrs' -> `Incomplete ((ur.team, wrs') :: wrs)))
    (`Complete (0, []))
    team_reports

let pp_week_report ppf = function
  | { status = Complete []; _ } -> Fmt.pf ppf "Complete"
  | { filename; status = Complete warnings; _ } ->
      Fmt.pf ppf "Complete@ @[<v 0>%a@]"
        (Fmt.list (Lint.Warning.pp ~filename))
        warnings
  | { filename; status = Not_found; _ } -> Fmt.pf ppf "Not found: %s" filename
  | { filename; status = Not_lint e; _ } ->
      Fmt.pf ppf "Lint error at %s@ @[<v 0>%a@]" filename
        (Fmt.list (fun ppf -> function
           | #Lint.Warning.t as w -> Lint.Warning.pp ~filename ppf w
           | #Lint.Error.t as e -> Lint.Error.pp ~filename ppf e))
        e

let pp_lint_errors ppf =
  Fmt.pf ppf "@[<v 0>%a@]"
    (Fmt.list (fun ppf (team, wrs) ->
         Fmt.pf ppf "Team %S:@;<1 2>%a" team.name
           (fun ppf ->
             Fmt.pf ppf "@[<v 0>%a@]"
               (Fmt.list (fun ppf report ->
                    Fmt.pf ppf "@[<hv 0>+ Report week %i: @[<v 0>%a@]@]"
                      report.week pp_week_report report)))
           wrs))

let pp_lint_report ppf (lint_report : lint_report) =
  match lint_report with
  | `Complete (total, warnings) -> (
      match warnings with
      | [] -> Fmt.pf ppf "[OK]: %i reports@." total
      | _ -> Fmt.pf ppf "[OK]: %i reports@ %a@." total pp_lint_errors warnings)
  | `Incomplete trl -> Fmt.pf ppf "%a@." pp_lint_errors trl

let is_valid : lint_report -> bool = function
  | `Complete _ -> true
  | `Incomplete _ -> false

let read_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  s

let aggregate ?okr_db admin_dir ~year ~weeks teams =
  let files =
    List.concat
    @@ List.concat
    @@ List.map
         (fun team ->
           List.map
             (fun member ->
               List.map
                 (fun week ->
                   file_path ~admin_dir ~year ~week
                     ~engineer_name:(Member.github member))
                 weeks)
             (members team))
         teams
  in
  let content =
    String.concat "\n"
    @@ List.map
         (fun file ->
           if not (Sys.file_exists file) then ""
           else
             try read_file file
             with Sys_error e ->
               Printf.eprintf
                 "An error ocurred while reading the input file(s).\n";
               Printf.eprintf "Error: %s\n" e;
               "")
         files
  in
  let md = Omd.of_string content in
  let report, _warnings =
    try Report.of_markdown ~report_kind:Engineer ?okr_db md
    with e ->
      Printf.eprintf
        "An error ocurred while parsing the input file(s). Run `lint` for more \
         information.\n\n\
         %s\n"
        (Printexc.to_string e);
      exit 1
  in
  report
