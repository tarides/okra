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

type file_status = Complete | Not_found | Not_lint of Lint.lint_error list
type week_report = { week : int; filename : string; status : file_status }
type user_report = { member : Member.t; week_reports : week_report list }
type team_report = { team : t; user_reports : user_report list }
type lint_report = team_report list

let file_path ~admin_dir ~week ~year ~engineer_name =
  Format.asprintf "%s/weekly/%4d/%02i/%s.md" admin_dir year week engineer_name

let lint_member_week admin_dir member ~week ~year =
  let fname =
    file_path ~admin_dir ~week ~year ~engineer_name:(Member.github member)
  in
  let status =
    match Sys.file_exists fname with
    | false -> Not_found
    | true -> (
        let ic = open_in fname in
        match
          Lint.lint ~include_sections:[ "Last week" ] ~ignore_sections:[] ic
        with
        | Ok () -> Complete
        | Error e -> Not_lint e)
  in
  { week; filename = fname; status }

let lint_member admin_dir ~year weeks member =
  let lint_member_week = lint_member_week admin_dir member in
  List.map (fun week -> lint_member_week ~year ~week) weeks

let lint_team admin_dir ~year ~weeks members =
  let lint_member = lint_member ~year admin_dir weeks in
  List.map (fun member -> { member; week_reports = lint_member member }) members

let lint admin_dir ~year ~weeks teams =
  let lint_team = lint_team ~year admin_dir ~weeks in
  List.map (fun team -> { team; user_reports = lint_team (members team) }) teams

let pp_report ppf = function
  | { status = Complete; _ } -> Fmt.pf ppf "Complete"
  | { filename; status = Not_found; _ } -> Fmt.pf ppf "Not found: %s" filename
  | { filename; status = Not_lint e; _ } ->
      Fmt.pf ppf "Lint error at %s@ @[<v 0>%a@]" filename
        (Fmt.list Lint.pp_error) e

let result_partition f =
  List.partition_map (fun x ->
      match f x with Ok i -> Either.Left i | Error e -> Either.Right e)

let pp_lint_report ppf lint_report =
  let pp_report_lint ppf report =
    Fmt.pf ppf "@[<hv 0>+ Report week %i: @[<v 0>%a@]@]" report.week pp_report
      report
  in
  let pp_member_lint ppf { member = _; week_reports } =
    let complete, not_complete =
      List.partition
        (fun r ->
          match r.status with
          | Complete -> true
          | Not_found | Not_lint _ -> false)
        week_reports
    in
    if not_complete = [] then Ok (List.length complete)
    else
      Error
        (fun () ->
          Fmt.pf ppf "@[%a@]"
            (Fmt.list ~sep:(Fmt.any "@;<1 0>") pp_report_lint)
            not_complete)
  in
  let pp_team_lint ppf { team; user_reports } =
    let complete, not_complete =
      result_partition (pp_member_lint ppf) user_reports
    in
    if not_complete = [] then Ok (List.fold_left ( + ) 0 complete)
    else
      Error
        (fun () ->
          Fmt.pf ppf "Team %S:@;<1 2>%a" (name team)
            (Fmt.list ~sep:(Fmt.any "@;<1 2>") (fun _ f -> f ()))
            not_complete)
  in
  let complete, not_complete =
    result_partition (pp_team_lint ppf) lint_report
  in
  if not_complete = [] then
    let total = List.fold_left ( + ) 0 complete in
    Fmt.pf ppf "[OK]: %i reports@." total
  else
    Fmt.pf ppf "@[<v 0>%a@]@."
      (Fmt.list ~sep:(Fmt.any "@;<1 2>") (fun _ f -> f ()))
      not_complete

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
  let report =
    try
      Report.of_markdown ~ignore_sections:[] ~include_sections:[ "Last week" ]
        ?okr_db md
    with e ->
      Printf.eprintf
        "An error ocurred while parsing the input file(s). Run `lint` for more \
         information.\n\n\
         %s\n"
        (Printexc.to_string e);
      exit 1
  in
  report
