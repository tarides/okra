(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
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

let ( let* ) = Result.bind

type lint_error =
  | Format_error of (int * string) list
  | Parsing_error of int option * Parser.warning
  | Invalid_total_time of string * Time.t * Time.t
  | Invalid_quarter of KR.Work.t
  | Invalid_objective of KR.warning

type lint_result = (unit, lint_error list) result

let fail_fmt_patterns =
  [
    (Str.regexp ".*\t", "Tab found. Use spaces for indentation (2 preferred).");
    ( Str.regexp ".*-  ",
      "Double space before text after bullet point ('-  text'), this can \
       confuse the parser. Use '- text'" );
    ( Str.regexp "^ -",
      "Single space used for indentation (' - text'). Remove or replace by 2 \
       or more spaces." );
    ( Str.regexp "^[ ]*\\*",
      "* used as bullet point, this can confuse the parser. Only use - as \
       bullet marker." );
    ( Str.regexp "^[ ]*\\+",
      "+ used as bullet point, this can confuse the parser. Only use - as \
       bullet marker." );
    ( Str.regexp "^[ ]+#",
      "Space found before title marker #. Start titles in first column." );
    ( Str.regexp "^[ ]+- Work Item 1",
      "Placeholder text detected. Replace with actual activity." );
  ]

let pp_error ppf = function
  | Format_error x ->
      let pp_msg ppf (pos, msg) = Fmt.pf ppf "Line %d: %s" pos msg in
      Fmt.pf ppf "@[<v 0>%a@,%d formatting errors found. Parsing aborted.@]"
        (Fmt.list ~sep:Fmt.sp pp_msg)
        x (List.length x)
  | Parsing_error (_, No_time_found kr) ->
      Fmt.pf ppf
        "@[<hv 2>In objective \"%a\":@ No time entry found. Each objective \
         must be followed by '- @@... (x days)'@]@,"
        KR.Heading.pp kr
  | Parsing_error (_, Invalid_time { kr; entry }) ->
      Fmt.pf ppf
        "@[<hv 2>In objective \"%a\":@ Invalid time entry %S found. Format is \
         '- @@eng1 (x days), @@eng2 (y days)'@ where x and y must be divisible \
         by 0.5@]@,"
        KR.Heading.pp kr entry
  | Invalid_total_time (s, t, total) ->
      Fmt.pf ppf
        "@[<hv 2>Invalid total time found for %s (reported %a, expected %a).@]@,"
        s Time.pp t Time.pp total
  | Parsing_error (_, Multiple_time_entries kr) ->
      Fmt.pf ppf
        "@[<hv 2>In objective \"%a\":@ Multiple time entries found. Only one \
         time entry should follow immediately after the objective.@]@,"
        KR.Heading.pp kr
  | Parsing_error (_, No_work_found kr) ->
      Fmt.pf ppf
        "@[<hv 2>In objective \"%a\":@ No work items found. This may indicate \
         an unreported parsing error. Remove the objective if it is without \
         work.@]@,"
        KR.Heading.pp kr
  | Parsing_error (_, No_KR_ID_found s) ->
      Fmt.pf ppf
        "@[<hv 2>In objective %S:@ No ID found. Objectives should be in the \
         format \"This is an objective (#123)\", where 123 is the objective \
         issue ID. For objectives that don't have an ID yet, use \"New KR\" \
         and for work without an objective use \"No KR\".@]@,"
        s
  | Parsing_error (_, No_project_found kr) ->
      Fmt.pf ppf
        "@[<hv 2>In objective \"%a\":@ No project found (starting with '#')@]@,"
        KR.Heading.pp kr
  | Parsing_error (_, Not_all_includes_accounted_for s) ->
      Fmt.pf ppf "Missing includes section: %a\n" Fmt.(list ~sep:comma string) s
  | Parsing_error (_, Invalid_markdown_in_work_items s) ->
      Fmt.pf ppf "@[<hv 2>Invalid markdown:@ %s@]@," s
  | Invalid_quarter kr ->
      Fmt.pf ppf
        "@[<hv 2>In objective \"%a\":@ Work logged on objective scheduled for \
         %a@]@,"
        KR.Work.pp kr (Fmt.option Quarter.pp) kr.quarter
  | Invalid_objective w -> (
      match w with
      | Objective_not_found x ->
          Fmt.pf ppf "@[<hv 2>Invalid objective:@ %S@]@," x.title
      | Migration { work_item; objective = None } ->
          Fmt.pf ppf
            "@[<hv 2>Invalid objective:@ \"%a\" is a work-item, you should use \
             an objective instead@]@,"
            KR.Work.pp work_item
      | Migration { work_item; objective = Some obj } ->
          Fmt.pf ppf
            "@[<hv 2>Invalid objective:@ \"%a\" is a work-item, you should use \
             its parent objective \"%a\" instead@]@,"
            KR.Work.pp work_item KR.Work.pp obj)

let string_of_error = Fmt.to_to_string pp_error

(* Check a single line for formatting errors returning a list of error messages
   with the position *)
let check_line line pos =
  List.fold_left
    (fun acc (regexp, msg) ->
      if Str.string_match regexp line 0 then (pos, msg) :: acc else acc)
    [] fail_fmt_patterns

let grep_n s lines =
  let re = Str.regexp_case_fold (".*" ^ Str.quote s ^ ".*") in
  List.find_map
    (fun (i, line) -> if Str.string_match re line 0 then Some i else None)
    lines

let lines_of_kr s lines = grep_n (Fmt.str "%a" KR.Heading.pp s) lines

let add_context lines = function
  | Parser.No_time_found s ->
      Parsing_error (lines_of_kr s lines, No_time_found s)
  | Parser.Invalid_time { kr; entry } ->
      Parsing_error (grep_n entry lines, Invalid_time { kr; entry })
  | Parser.Multiple_time_entries s ->
      Parsing_error (lines_of_kr s lines, Multiple_time_entries s)
  | Parser.No_work_found s ->
      Parsing_error (lines_of_kr s lines, No_work_found s)
  | Parser.No_KR_ID_found s -> Parsing_error (grep_n s lines, No_KR_ID_found s)
  | Parser.No_project_found s ->
      Parsing_error (lines_of_kr s lines, No_project_found s)
  | Parser.Not_all_includes_accounted_for s ->
      Parsing_error (None, Not_all_includes_accounted_for s)
  | Parser.Invalid_markdown_in_work_items s ->
      Parsing_error (grep_n s lines, Invalid_markdown_in_work_items s)

let check_total_time ?check_time (krs : KR.t list) report_kind =
  match report_kind with
  | Parser.Team -> Ok ()
  | Parser.Engineer ->
      let expected = Option.value check_time ~default:(Time.days 5.) in
      let tbl = Hashtbl.create 7 in
      List.iter
        (fun (kr : KR.t) ->
          Hashtbl.iter
            (fun name time ->
              let time =
                let open Time in
                match Hashtbl.find_opt tbl name with
                | Some x -> x +. time
                | None -> time
              in
              Hashtbl.replace tbl name time)
            kr.time_per_engineer)
        krs;
      Hashtbl.fold
        (fun name time acc ->
          let* () = acc in
          if Time.equal time expected then Ok ()
          else Error (Invalid_total_time (name, time, expected)))
        tbl (Ok ())

let check_quarters quarter krs warnings =
  List.fold_left
    (fun acc kr ->
      match kr.KR.kind with
      | Meta _ -> acc
      | Work w ->
          if Quarter.check quarter w.quarter then acc
          else Invalid_quarter w :: acc)
    warnings krs

let maybe_emit warnings =
  match warnings with [] -> Ok () | warnings -> Error warnings

let ( let* ) = Result.bind

(* Parse document as a string to check for aggregation errors (assumes no
   formatting errors) *)
let check_document ?okr_db ~include_sections ~ignore_sections ?check_time
    ?report_kind ~filename s =
  let quarter = Quarter.of_filename ~filename in
  let lines =
    String.split_on_char '\n' s |> List.mapi (fun i s -> (i + 1, s))
  in
  let md = Omd.of_string s in
  let kind = Option.value report_kind ~default:Parser.default_report_kind in
  let okrs, warnings =
    Parser.of_markdown ~include_sections ~ignore_sections kind md
  in
  let warnings =
    let warnings = List.map (add_context lines) warnings in
    match check_total_time ?check_time okrs kind with
    | Ok () -> warnings
    | Error w -> w :: warnings
  in
  let* () = maybe_emit warnings in
  let report, report_warnings = Report.of_krs ?okr_db okrs in
  let warnings =
    List.fold_left
      (fun acc w -> Invalid_objective w :: acc)
      warnings report_warnings
  in
  let* () = maybe_emit warnings in
  let krs = Report.all_krs report in
  let warnings = check_quarters quarter krs warnings in
  let* () = maybe_emit warnings in
  Ok ()

let document_ok ?okr_db ~include_sections ~ignore_sections ~format_errors
    ?check_time ?report_kind ~filename s =
  if !format_errors <> [] then
    Error
      [
        Format_error
          (List.sort (fun (x, _) (y, _) -> compare x y) !format_errors);
      ]
  else
    check_document ?okr_db ~include_sections ~ignore_sections ?check_time
      ?report_kind ~filename s

let lint_string_list ?okr_db ?(include_sections = []) ?(ignore_sections = [])
    ?check_time ?report_kind ~filename lines =
  let format_errors = ref [] in
  let rec check_and_read buf pos = function
    | [] -> Buffer.contents buf
    | line :: rest ->
        format_errors := check_line line pos @ !format_errors;
        Buffer.add_string buf line;
        Buffer.add_string buf "\n";
        check_and_read buf (pos + 1) rest
  in
  let s = check_and_read (Buffer.create 1024) 1 lines in
  document_ok ?okr_db ~include_sections ~ignore_sections ~format_errors
    ?check_time ?report_kind ~filename s

let lint ?okr_db ?(include_sections = []) ?(ignore_sections = []) ?check_time
    ?report_kind ~filename ic =
  let format_errors = ref [] in
  let rec check_and_read buf ic pos =
    try
      let line = input_line ic in
      format_errors := check_line line pos @ !format_errors;
      Buffer.add_string buf line;
      Buffer.add_string buf "\n";
      check_and_read buf ic (pos + 1)
    with
    | End_of_file -> Buffer.contents buf
    | e -> raise e
  in
  let s = check_and_read (Buffer.create 1024) ic 1 in
  document_ok ?okr_db ~include_sections ~ignore_sections ~format_errors
    ?check_time ?report_kind ~filename s

let short_messages_of_error file_name =
  let short_message line_number msg =
    [ Printf.sprintf "%s:%d:%s" file_name line_number msg ]
  in
  let short_messagef line_number_opt fmt =
    let line_number = Option.value ~default:1 line_number_opt in
    Format.kasprintf (short_message line_number) fmt
  in
  function
  | Format_error errs ->
      List.concat_map
        (fun (line_number, message) -> short_message line_number message)
        errs
  | Parsing_error (line_number, No_time_found kr) ->
      short_messagef line_number "No time found in \"%a\"" KR.Heading.pp kr
  | Parsing_error (line_number, Invalid_time { kr; entry }) ->
      short_messagef line_number "Invalid time entry %S in \"%a\"" entry
        KR.Heading.pp kr
  | Invalid_total_time (s, t, total) ->
      short_messagef None "Invalid total time for %S (%a/%a)" s Time.pp t
        Time.pp total
  | Parsing_error (line_number, Multiple_time_entries kr) ->
      short_messagef line_number "Multiple time entries for \"%a\""
        KR.Heading.pp kr
  | Parsing_error (line_number, No_work_found kr) ->
      short_messagef line_number "No work found for \"%a\"" KR.Heading.pp kr
  | Parsing_error (line_number, No_KR_ID_found kr) ->
      short_messagef line_number "No KR ID found for %S" kr
  | Parsing_error (line_number, No_project_found kr) ->
      short_messagef line_number "No project found for \"%a\"" KR.Heading.pp kr
  | Parsing_error (line_number, Not_all_includes_accounted_for l) ->
      short_messagef line_number "Missing includes section: %s"
        (String.concat ", " l)
  | Parsing_error (line_number, Invalid_markdown_in_work_items s) ->
      short_messagef line_number "Invalid markdown in work items: %s" s
  | Invalid_quarter kr ->
      short_messagef None "Using KR of invalid quarter: \"%a\" (%a)" KR.Work.pp
        kr (Fmt.option Quarter.pp) kr.quarter
  | Invalid_objective w -> (
      match w with
      | Objective_not_found x ->
          short_messagef None "Invalid objective: %S" x.title
      | Migration { work_item; objective = None } ->
          short_messagef None
            "Invalid objective:@ \"%a\" is a work-item, an objective should be \
             used instead"
            KR.Work.pp work_item
      | Migration { work_item; objective = Some obj } ->
          short_messagef None
            "Invalid objective:@ \"%a\" is a work-item, its parent objective \
             \"%a\" should be used instead"
            KR.Work.pp work_item KR.Work.pp obj)
