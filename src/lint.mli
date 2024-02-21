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

type lint_error =
  | Format_error of (int * string) list
  | No_version_found
  | Invalid_version of int option * string
  | Unsupported_version of int option * string
  | No_time_found of int option * string
  | Invalid_time of int option * string
  | Multiple_time_entries of int option * string
  | No_work_found of int option * string
  | No_KR_ID_found of int option * string
  | No_project_found of int option * string
  | Not_all_includes of string list

type lint_result = (unit, lint_error) result

val lint :
  ?okr_db:Masterdb.t ->
  ?include_sections:string list ->
  ?ignore_sections:string list ->
  in_channel ->
  lint_result

val lint_string_list :
  ?okr_db:Masterdb.t ->
  ?include_sections:string list ->
  ?ignore_sections:string list ->
  string list ->
  lint_result
(** [lint_string_list] is like {!lint} except the input is a list of lines *)

val string_of_error : lint_error -> string
val short_messages_of_error : string -> lint_error -> string list
val pp_error : Format.formatter -> lint_error -> unit
