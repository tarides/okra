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

open Cmdliner

let get_or_error = function
  | Ok v -> v
  | Error (`Msg m) ->
      Fmt.epr "%s" m;
      exit 1

let lint t =
  let repo = get_or_error @@ Common.repo t in
  let weeks = Common.weeks t in
  let year = Common.year t in
  let teams = Common.teams t in
  (* Here the linting is done week-by-week. *)
  let lint_report = Okra.Team.lint repo ~year ~weeks teams in
  Format.printf "%a" Okra.Team.pp_lint_report lint_report;
  if not (Okra.Team.is_valid lint_report) then exit 1

let aggregate t =
  let repo = get_or_error @@ Common.repo t in
  let okr_db = Common.okr_db t in
  let teams = Common.teams t in
  let year = Common.year t in
  let weeks = Common.weeks t in
  let report = Okra.Team.aggregate ?okr_db repo ~year ~weeks teams in
  let filters = Common.filter t in
  let report = Okra.Filter.apply filters report in
  let pp =
    Okra.Report.pp ~show_time:true ~show_time_calc:false ~show_engineers:true
  in
  Okra.Printer.to_channel stdout pp report

let lint_cmd =
  let doc = "Lint reports for a team." in
  let info = Cmd.info "lint" ~doc in
  Cmd.v info Term.(const lint $ Common.term)

let aggregate_cmd =
  let doc = "Aggregate reports for a team." in
  let info = Cmd.info "aggregate" ~doc in
  Cmd.v info Term.(const aggregate $ Common.term)

let cmd =
  let doc = "Work on multiple reports for a team" in
  let info = Cmd.info "team" ~doc in
  Cmd.group info [ aggregate_cmd; lint_cmd ]
