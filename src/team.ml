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

type report =
  | Not_found of string
  | Complete of string
  | Erroneous of (string * Lint.lint_error)

type lint_report = (t * (Member.t * (int * report) list) list) list

let file_path ~admin_dir ~week ~year ~engineer_name =
  Format.asprintf "%s/weekly/%4d/%02i/%s.md" admin_dir year week engineer_name

let lint_member_week admin_dir member ~week ~year =
  let fname =
    file_path ~admin_dir ~week ~year ~engineer_name:(Member.github member)
  in
  match Sys.file_exists fname with
  | false -> Not_found fname
  | true -> (
      let ic = open_in fname in
      match
        Lint.lint ~include_sections:[ "Last week" ] ~ignore_sections:[] ic
      with
      | Ok () -> Complete fname
      | Error e -> Erroneous (fname, e))

let lint_member admin_dir ~year weeks member =
  let lint_member_week = lint_member_week admin_dir member in
  List.map (fun week -> (week, lint_member_week ~year ~week)) weeks

let lint_team admin_dir ~year ~weeks members =
  let lint_member = lint_member ~year admin_dir weeks in
  List.map (fun member -> (member, lint_member member)) members

let lint admin_dir ~year ~weeks teams =
  let lint_team = lint_team ~year admin_dir ~weeks in
  List.map (fun team -> (team, lint_team (members team))) teams

let pp_report ppf = function
  | Not_found fpath -> Fmt.pf ppf "Not found: %s" fpath
  | Complete _ -> Fmt.pf ppf "Complete"
  | Erroneous (fpath, e) ->
      Fmt.pf ppf "Lint error at %s @[<v 0>%a@]" fpath Lint.pp_error e

let pp_lint_report ppf lint_report =
  let pp_report_lint ppf (week, report) =
    Fmt.pf ppf "@[<hv 0>+ Report week %i: @[<v 0>%a@]@]" week pp_report report
  in
  let pp_member_lint ppf (member, member_lint) =
    Fmt.pf ppf "+ %s@;<1 4>%a" (Member.name member)
      (Fmt.list ~sep:(Fmt.any "@;<1 4>") pp_report_lint)
      member_lint
  in
  let pp_team_lint ppf (team, members_list) =
    Fmt.pf ppf "=== %s ===@;<1 2>%a" (name team)
      (Fmt.list ~sep:(Fmt.any "@;<1 2>") pp_member_lint)
      members_list
  in
  Fmt.pf ppf "@[<v 0>%a@]@."
    (Fmt.list ~sep:(Fmt.any "@;<1 2>") pp_team_lint)
    lint_report

let read_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  s

let aggregate ?okr_db admin_dir ~year ~week teams =
  let files =
    List.concat
    @@ List.map
         (fun team ->
           List.map
             (fun member ->
               file_path ~admin_dir ~year ~week
                 ~engineer_name:(Member.github member))
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
