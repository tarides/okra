(*
 * Copyright (c) 2021-22 Magnus Skjegstad <magnus@skjegstad.com>
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

type t = {
  c : Common.t;
  md : Omd.doc;
  append_to : string option;
  output : out_channel;
}

open Cmdliner

let append_to =
  let info =
    Arg.info [ "append-to" ]
      ~doc:
        "Take the reports passed as positional arguments and merge them into \
         the already-generated, aggregate report."
  in
  Arg.value (Arg.opt (Arg.some Arg.file) None info)

let read_file f =
  let ic = open_in f in
  let s = really_input_string ic (in_channel_length ic) in
  close_in ic;
  s

let run conf =
  let oc = Common.output conf.c in
  let okr_db = Common.okr_db conf.c in
  let existing_report =
    match conf.append_to with
    | None -> None
    | Some file ->
        let content = read_file file in
        let exisiting, _warnings =
          Okra.Report.of_markdown ?okr_db (Omd.of_string content)
        in
        Some exisiting
  in
  let okrs, _warnings =
    try
      Okra.Report.of_markdown ?existing_report
        ~ignore_sections:(Common.ignore_sections conf.c)
        ~include_sections:(Common.include_sections conf.c)
        ?report_kind:(Common.report_kind conf.c)
        ?okr_db conf.md
    with e ->
      Logs.err (fun l ->
          l
            "An error ocurred while parsing the input file(s). Run `lint` for \
             more information.\n\n\
             %s\n"
            (Printexc.to_string e));
      exit 1
  in
  let filters = Common.filter conf.c in
  let okrs = Okra.Filter.apply filters okrs in
  let pp =
    Okra.Report.pp ~show_time:(Common.with_days conf.c) ~show_time_calc:false
      ~show_engineers:(Common.with_names conf.c)
  in
  Okra.Printer.to_channel oc pp okrs

let term =
  let open Let_syntax_cmdliner in
  let+ c = Common.term
  and+ append_to = append_to
  and+ md = Common.input
  and+ input_files = Common.input_files
  and+ in_place = Common.in_place in
  let output = Common.output ~input_files ~in_place c in
  run { c; md; append_to; output }

let cmd =
  let info =
    Cmd.info "cat" ~doc:"parse and concatenate reports"
      ~man:
        [
          `S Manpage.s_description;
          `P
            "Parses one or more OKR reports and outputs a report aggregated \
             per KR. See below for options for modifying the output format.";
        ]
  in
  Cmd.v info term
