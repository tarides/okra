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

type warning =
  | No_time_found of string  (** Record found without a time record *)
  | Multiple_time_entries of string  (** More than one time entry found *)
  | Invalid_time of string  (** Time record found, but has errors *)
  | No_work_found of string  (** No work items found under KR *)
  | No_KR_ID_found of string  (** Empty or no KR ID *)
  | No_project_found of string  (** No project found *)
  | Not_all_includes_accounted_for of string list
      (** There should be a section for all include sections passed to the parser *)
  | Invalid_markdown_in_work_items of string
      (** Subset of markdown not supported in work items *)

type markdown = Omd.doc
(** The type for markdown files. *)

val of_markdown :
  ?ignore_sections:string list ->
  ?include_sections:string list ->
  markdown ->
  KR.t list * warning list
(** Process markdown data from omd. Optionally [ignore_sections] can be used to
    ignore specific sections, or [include_sections] can be used to only process
    specific sections. *)
