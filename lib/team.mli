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

module Member : sig
  type t

  val make : name:string -> github:string -> t
  val name : t -> string
  val github : t -> string
end

type t

val make : name:string -> members:Member.t list -> t
val name : t -> string
val members : t -> Member.t list

type lint_report

val aggregate :
  ?okr_db:Masterdb.t ->
  string ->
  year:int ->
  weeks:int list ->
  t list ->
  Report.t
(** [aggregate admin_dir weeks teams] aggregates the reports of the teams for the
    given weeks. *)

val lint : string -> year:int -> weeks:int list -> t list -> lint_report
(** [lint admin_dir weeks teams] generates a [lint_report] for the teams at the
    given weeks. *)

val pp_lint_report : Format.formatter -> lint_report -> unit
