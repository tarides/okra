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

module Error = struct
  type t =
    | Format_error of (int * string) list
    | Parsing_error of int option * Parser.Warning.t
    | Invalid_total_time of string * Time.t * Time.t
    | Invalid_quarter of int option * KR.Work.t
    | Invalid_objective of int option * KR.Warning.t

  let pp_error_kw =
    Fmt.styled `Bold
    @@ Fmt.styled (`Fg `Red)
    @@ fun ppf () -> Fmt.pf ppf "%s" "Error"

  let pp ~filename ppf =
    let pp_loc =
      Fmt.styled `Bold @@ fun ppf (filename, line_number) ->
      Fmt.pf ppf "File %S, line %i" filename line_number
    in
    let pf line_number_opt k =
      let line_number = Option.value ~default:1 line_number_opt in
      k (fun ppf ->
          Fmt.pf ppf "@[<hv 0>@{<loc>%a@}:@\n%a: " pp_loc
            (filename, line_number) pp_error_kw ();
          Fmt.kpf (fun ppf -> Fmt.pf ppf "@]@,") ppf)
    in
    function
    | Format_error x ->
        let pp_msg ppf (pos, msg) =
          Fmt.pf ppf "File %S, line %d:@\nError: %s" filename pos msg
        in
        Fmt.pf ppf "@[<v 0>%a@]" (Fmt.list ~sep:Fmt.sp pp_msg) x
    | Parsing_error (line_number, w) ->
        pf line_number (fun m -> m ppf "@[<hv 0>%a@]" Parser.Warning.pp w)
    | Invalid_total_time (s, t, total) ->
        pf None (fun m ->
            m ppf
              "@[<hv 0>Invalid total time found for %s:@ Reported %a, expected \
               %a.@]"
              s Time.pp t Time.pp total)
    | Invalid_quarter (line_number, kr) ->
        pf line_number (fun m ->
            m ppf
              "@[<hv 0>In objective \"%a\":@ Work logged on objective \
               scheduled for %a@]"
              KR.Work.pp kr (Fmt.option Quarter.pp) kr.quarter)
    | Invalid_objective (line_number, w) ->
        pf line_number (fun m -> m ppf "@[<hv 0>%a@]" KR.Warning.pp w)

  let pp_short ~filename ppf =
    let pp_loc =
      Fmt.styled `Bold @@ fun ppf (filename, line_number) ->
      Fmt.pf ppf "%s:%i" filename line_number
    in
    let pf line_number_opt k =
      let line_number = Option.value ~default:1 line_number_opt in
      k (fun ppf ->
          Fmt.pf ppf "@[<hv 0>@{<loc>%a@}: " pp_loc (filename, line_number);
          Fmt.kpf (fun ppf -> Fmt.pf ppf "@]@,") ppf)
    in
    function
    | Format_error errs ->
        List.iter
          (fun (line_number, message) ->
            pf (Some line_number) (fun m -> m ppf "%s" message))
          errs
    | Parsing_error (line_number, w) ->
        pf line_number (fun m -> m ppf "%a" Parser.Warning.pp_short w)
    | Invalid_total_time (s, t, total) ->
        pf None (fun m ->
            m ppf "Invalid total time for %S (%a/%a)" s Time.pp t Time.pp total)
    | Invalid_quarter (line_number, kr) ->
        pf line_number (fun m ->
            m ppf "Using KR of invalid quarter: \"%a\" (%a)" KR.Work.pp kr
              (Fmt.option Quarter.pp) kr.quarter)
    | Invalid_objective (line_number, w) ->
        pf line_number (fun m -> m ppf "%a" KR.Warning.pp_short w)
end

type lint_result = (unit, Error.t list) result

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

let add_context lines w =
  let line_number =
    match Parser.Warning.greppable w with
    | Some s -> grep_n s lines
    | None -> None
  in
  Error.Parsing_error (line_number, w)

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
          else Error (Error.Invalid_total_time (name, time, expected)))
        tbl (Ok ())

let check_quarters quarter krs warnings lines =
  List.fold_left
    (fun acc kr ->
      match kr.KR.kind with
      | Meta _ -> acc
      | Work w ->
          if Quarter.check quarter w.quarter then acc
          else
            let line_number = grep_n w.title lines in
            Error.Invalid_quarter (line_number, w) :: acc)
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
      (fun acc w ->
        let line_number =
          match KR.Warning.greppable w with
          | Some s -> grep_n s lines
          | None -> None
        in
        Error.Invalid_objective (line_number, w) :: acc)
      warnings report_warnings
  in
  let* () = maybe_emit warnings in
  let krs = Report.all_krs report in
  let warnings = check_quarters quarter krs warnings lines in
  let* () = maybe_emit warnings in
  Ok ()

let document_ok ?okr_db ~include_sections ~ignore_sections ~format_errors
    ?check_time ?report_kind ~filename s =
  if !format_errors <> [] then
    Error
      [
        Error.Format_error
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
