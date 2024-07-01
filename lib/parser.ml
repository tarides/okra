(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2021 Patrick Ferris <pf341@patricoferris.com>
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

let src = Logs.Src.create "okra.parser"

module Log = (val Logs.src_log src : Logs.LOG)
open Omd

module Warning = struct
  type t =
    | No_time_found of KR.Heading.t
    | Multiple_time_entries of KR.Heading.t
    | Invalid_time of { kr : KR.Heading.t; entry : string }
    | No_work_found of KR.Heading.t
    | No_KR_ID_found of string
    | No_project_found of KR.Heading.t
    | Not_all_includes_accounted_for of string list

  let pp ppf = function
    | No_time_found kr ->
        Fmt.pf ppf
          "In objective \"%a\":@ No time entry found. Each objective must be \
           followed by '- @@... (x days)'"
          KR.Heading.pp kr
    | Invalid_time { kr; entry } ->
        Fmt.pf ppf
          "In objective \"%a\":@ Invalid time entry %S found. Format is '- \
           @@eng1 (x days), @@eng2 (y days)'@ where x and y must be divisible \
           by 0.5"
          KR.Heading.pp kr entry
    | Multiple_time_entries kr ->
        Fmt.pf ppf
          "In objective \"%a\":@ Multiple time entries found. Only one time \
           entry should follow immediately after the objective."
          KR.Heading.pp kr
    | No_work_found kr ->
        Fmt.pf ppf
          "In objective \"%a\":@ No work items found. This may indicate an \
           unreported parsing error. Remove the objective if it is without \
           work."
          KR.Heading.pp kr
    | No_KR_ID_found s ->
        Fmt.pf ppf
          "In objective %S:@ No ID found. Objectives should be in the format \
           \"This is an objective (#123)\", where 123 is the objective issue \
           ID. For objectives that don't have an ID yet, use \"New KR\" and \
           for work without an objective use \"No KR\"."
          s
    | No_project_found kr ->
        Fmt.pf ppf "In objective \"%a\":@ No project found (starting with '#')"
          KR.Heading.pp kr
    | Not_all_includes_accounted_for s ->
        Fmt.pf ppf "Missing includes section:@ %a"
          Fmt.(list ~sep:comma string)
          s

  let pp_short ppf = function
    | No_time_found kr -> Fmt.pf ppf "No time found in \"%a\"" KR.Heading.pp kr
    | Invalid_time { kr; entry } ->
        Fmt.pf ppf "Invalid time entry %S in \"%a\"" entry KR.Heading.pp kr
    | Multiple_time_entries kr ->
        Fmt.pf ppf "Multiple time entries for \"%a\"" KR.Heading.pp kr
    | No_work_found kr -> Fmt.pf ppf "No work found for \"%a\"" KR.Heading.pp kr
    | No_KR_ID_found kr -> Fmt.pf ppf "No KR ID found for %S" kr
    | No_project_found kr ->
        Fmt.pf ppf "No project found for \"%a\"" KR.Heading.pp kr
    | Not_all_includes_accounted_for l ->
        Fmt.pf ppf "Missing includes section: %s" (String.concat ", " l)

  let greppable = function
    | No_time_found s -> Some (Fmt.str "%a" KR.Heading.pp s)
    | Invalid_time { kr = _; entry } -> Some entry
    | Multiple_time_entries s -> Some (Fmt.str "%a" KR.Heading.pp s)
    | No_work_found s -> Some (Fmt.str "%a" KR.Heading.pp s)
    | No_KR_ID_found s -> Some s
    | No_project_found s -> Some (Fmt.str "%a" KR.Heading.pp s)
    | Not_all_includes_accounted_for _ -> None
end

(* Types for parsing the AST *)
type t =
  | KR_heading of KR.Heading.t (* Title and ID of workitem *)
  | Work of Item.t list (* Work items *)
  | Time of string

type markdown = Omd.doc
type report_kind = Engineer | Team

let warnings : Warning.t list ref = ref []
let add_warning w = warnings := w :: !warnings
let obj_re = Str.regexp "\\(.+\\) (\\([a-zA-Z ]+\\))$"
(* Header: This is an objective (Tech lead name) *)

let is_time_block = function
  | [ Paragraph (_, Text (_, s)) ] -> String.get (String.trim s) 0 = '@'
  | _ -> false

let time_entry_regexp =
  let open Re in
  let user = seq [ char '@'; group (rep1 (alt [ wordc; char '-' ])) ] in
  let number =
    let with_int_part =
      let int_part = rep1 digit in
      let fract_part = seq [ char '.'; opt (alt [ char '0'; char '5' ]) ] in
      seq [ int_part; opt fract_part ]
    in
    let without_int_part = seq [ str ".5"; opt (char '0') ] in
    group (alt [ with_int_part; without_int_part ])
  in
  let time_unit = group (alt [ str "day" ]) in
  let time = seq [ number; rep space; time_unit; opt (char 's') ] in
  compile @@ seq [ start; user; rep space; char '('; time; char ')'; stop ]

let dump_elt ppf = function
  | KR_heading x -> Fmt.pf ppf "KR %a" KR.Heading.pp x
  | Work w -> Fmt.pf ppf "W: %a" Fmt.Dump.(list Item.dump) w
  | Time _ -> Fmt.pf ppf "Time: <not shown>"

let dump ppf okr = Fmt.Dump.list dump_elt ppf okr
let err_no_project s = add_warning (No_project_found s)
let err_multiple_time_entries s = add_warning (Multiple_time_entries s)
let err_no_work s = add_warning (No_work_found s)
let err_no_id s = add_warning (No_KR_ID_found s)
let err_time ~kr ~entry = add_warning (Invalid_time { kr; entry })
let err_no_time s = add_warning (No_time_found s)
let err_missing_includes s = add_warning (Not_all_includes_accounted_for s)
let inline_to_string = Fmt.to_to_string Item.pp_inline
let item_to_string = Fmt.to_to_string Item.pp

let kr ~project ~objective = function
  | [] -> None
  | l ->
      (* This function expects a list of entries for the same KR, typically
         corresponding to a set of weekly reports. Each list item will consist
         of a list of okr_t items, which provides time, work items etc for this
         entry.

         This function will aggregate all entries for the same KR in an
         okr_entry record for easier processing later. *)
      let kr_heading = ref None in
      let time_entries = ref [] in

      (* Assume each item in list has the same O/KR/Proj, so just parse the
         first one *)
      (* todo we could sanity check here by verifying that every entry has the
         same KR/O *)
      List.iter
        (function
          | KR_heading s -> kr_heading := Some s
          | Time t ->
              let t_split = String.split_on_char ',' (String.trim t) in
              let entry =
                List.filter_map
                  (fun s ->
                    let ( let* ) = Option.bind in
                    let s = String.trim s in
                    match
                      let* grp = Re.exec_opt time_entry_regexp s in
                      let* user = Re.Group.get_opt grp 1 in
                      let* s_time = Re.Group.get_opt grp 2 in
                      let* f_time = Float.of_string_opt s_time in
                      let* s_unit = Re.Group.get_opt grp 3 in
                      let* t_unit = Time.Unit.of_string s_unit in
                      let time = { Time.unit = t_unit; data = f_time } in
                      Some (user, time)
                    with
                    | Some x -> Some x
                    | None ->
                        let kr =
                          Option.value !kr_heading
                            ~default:(KR.Heading.Work ("", None))
                        in
                        err_time ~kr ~entry:t;
                        None)
                  t_split
              in
              time_entries := [ entry ] :: !time_entries
          | _ -> ())
        l;

      let kr = Option.value !kr_heading ~default:(KR.Heading.Work ("", None)) in

      let () =
        match l with
        | [] -> ()
        | KR_heading _ :: Time _ :: _ -> ()
        | _ -> err_no_time kr
      in

      let work = List.filter_map (function Work e -> Some e | _ -> None) l in
      (if work = [] then
         match !kr_heading with
         | Some (KR.Heading.Meta KR.Meta.Off) -> ()
         | Some _ -> err_no_work kr
         | None -> ());

      let kind =
        let quarter = None in
        match !kr_heading with
        | Some (Meta x) -> KR.Kind.Meta x
        | Some (Work (title, id)) ->
            let id =
              match id with
              | None ->
                  err_no_id title;
                  KR.Work.Id.No_KR
              | Some id -> id
            in
            KR.Kind.Work (KR.Work.v ~title ~id ~quarter)
        | None ->
            let id = KR.Work.Id.No_KR in
            let title = "" in
            KR.Kind.Work (KR.Work.v ~title ~id ~quarter)
      in

      let time_entries =
        match !time_entries with
        (* [No_time_found] already reported. *)
        | [] -> []
        | [ e ] -> e
        | x :: _ ->
            err_multiple_time_entries kr;
            x
      in

      let project = String.trim project in
      if project = "" then err_no_project kr;
      let objective = String.trim objective in
      Some (KR.v ~kind ~project ~objective ~time_entries work)

let block_okr = function
  | Paragraph (_, x) ->
      let okr_title = String.trim (inline_to_string x) in
      [ KR_heading (KR.Heading.of_string okr_title) ]
  | List (_, _, _, bls) ->
      List.map
        (fun bl ->
          if is_time_block bl then
            (* todo verify that this is true *)
            let time_s = String.concat "" (List.map item_to_string bl) in
            Time time_s
          else Work bl)
        bls
  | _ -> []

let strip_obj_lead s =
  match Str.string_match obj_re (String.trim s) 0 with
  | false -> String.trim s
  | true -> String.trim (Str.matched_group 1 s)

type state = {
  mutable current_o : string;
  mutable current_proj : string;
  ignore_sections : string list;
  include_sections : string list;
}

let init ?(ignore_sections = []) ?(include_sections = []) () =
  { current_o = ""; current_proj = ""; ignore_sections; include_sections }

let ignore_section t =
  match t.ignore_sections with
  | [] -> false
  | l ->
      (* ignore if proj or obj is in ignore_sections *)
      List.mem (String.uppercase_ascii t.current_proj) l
      || List.mem (String.uppercase_ascii t.current_o) t.ignore_sections

let include_section t =
  match t.include_sections with
  | [] -> Some "all"
  | l -> (
      match
        ( List.find_opt String.(equal @@ uppercase_ascii t.current_proj) l,
          List.find_opt String.(equal @@ uppercase_ascii t.current_o) l )
      with
      | (Some _ as t), _ | None, (Some _ as t) -> t
      | _ -> None)

let process_block state acc = function
  | Heading (_, n, il) ->
      let title =
        match il with
        (* Display header with level, strip lead from objectives if present *)
        | Text (_, s) -> strip_obj_lead s
        | _ -> "None"
      in
      let () =
        match n with
        | 2 -> state.current_o <- title
        | 1 ->
            state.current_o <- "";
            state.current_proj <- title
        | _ -> (* TODO: do now discard intermediate subsections *) ()
      in
      acc
  | List (_, _, _, bls) ->
      List.fold_left
        (fun ((sections, krs) as acc) xs ->
          let includes = include_section state in
          if ignore_section state || Option.is_none includes then acc
          else
            let block = List.concat (List.map block_okr xs) in
            Log.debug (fun l -> l "items: %a" dump block);
            match
              kr ~project:state.current_proj ~objective:state.current_o block
            with
            (* Safe to Option.get given if-then-else *)
            | None -> (Option.get includes :: sections, krs)
            | Some x -> (Option.get includes :: sections, x :: krs))
        acc bls
  | _ ->
      (* FIXME: also keep floating text *)
      acc

let process t ast = List.fold_left (process_block t) ([], []) ast

let check_includes u_includes (includes : string list) =
  let missing =
    List.(
      fold_left
        (fun acc v -> if mem v includes then acc else v :: acc)
        [] u_includes)
  in
  if missing = [] then () else err_missing_includes missing

let default_report_kind = Team

let of_markdown ?(ignore_sections = []) ?(include_sections = []) report_kind ast
    =
  warnings := [];
  let include_sections =
    match report_kind with
    | Engineer -> [ "Last week" ]
    | Team -> include_sections
  in
  let ignore_sections =
    match report_kind with Engineer -> ignore_sections | Team -> []
  in
  let u_ignore = List.map String.uppercase_ascii ignore_sections in
  let u_include = List.map String.uppercase_ascii include_sections in
  let state = init ~ignore_sections:u_ignore ~include_sections:u_include () in
  let includes, krs = process state ast in
  check_includes u_include (List.sort_uniq String.compare includes);
  (List.rev krs, List.rev !warnings)
