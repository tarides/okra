(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
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

type format = Short | Pretty
type t = { c : Common.t; input_files : string list; format : format }

open Cmdliner

let with_in_file path f =
  let ic = Stdlib.open_in path in
  Fun.protect ~finally:(fun () -> Stdlib.close_in_noerr ic) (fun () -> f ic)

let green = Fmt.(styled `Green string)
let red = Fmt.(styled `Red string)
let pp_status style ppf s = Fmt.(pf ppf "[%a]" style s)

let run conf =
  let collect_errors name ic =
    match
      Okra.Lint.lint ?okr_db:(Common.okr_db conf.c)
        ?check_time:(Common.check_time conf.c)
        ~include_sections:(Common.include_sections conf.c)
        ~ignore_sections:(Common.ignore_sections conf.c)
        ic
    with
    | Ok () -> (name, [])
    | Error errors -> (name, errors)
  in
  let report_error name e =
    match conf.format with
    | Pretty ->
        Fmt.(
          pf stderr "%a: %s\n\n%s" (pp_status red) "ERROR(S)" name
            (Okra.Lint.string_of_error e))
    | Short ->
        List.iter print_endline (Okra.Lint.short_messages_of_error name e)
  in
  let report_ok (name, _) =
    match conf.format with
    | Pretty -> Fmt.pr "%a: %s\n%!" (pp_status green) "OK" name
    | Short -> ()
  in
  try
    let errors =
      if conf.input_files <> [] then
        List.map
          (fun path -> with_in_file path (fun ic -> collect_errors path ic))
          conf.input_files
      else [ collect_errors "<stdin>" stdin ]
    in
    let correct, errors =
      List.partition (fun (_name, err) -> err = []) errors
    in
    List.iter report_ok (List.rev correct);
    List.iter
      (fun (name, error) -> List.iter (report_error name) error)
      (List.rev errors);
    if errors <> [] then exit 1
  with e ->
    Printf.fprintf stderr "Caught unknown error while linting:\n\n";
    raise e

let format_term =
  let open Let_syntax_cmdliner in
  let+ short =
    Arg.(
      value
      & Arg.flag
      & Arg.info
          ~doc:
            "Output to stdout and emit one line per error,\n\
             using the format `file:line:message`."
          [ "short" ])
  in
  if short then Short else Pretty

let term =
  let open Let_syntax_cmdliner in
  let+ c = Common.term
  and+ format = format_term
  and+ input_files = Common.input_files in
  run { c; input_files; format }

let cmd =
  let info =
    Cmd.info "lint"
      ~doc:"Check for formatting errors and missing information in the report"
      ~man:
        [
          `S Manpage.s_description;
          `P
            "Check for general formatting errors, then attempt to parse the \
             report and look for inconsistencies.";
          `P "Reads from stdin if no files are specified.";
        ]
  in
  Cmd.v info term
