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

type t = private {
  counter : int;
  project : string;
  objective : string;
  title : string;
  id : string option;
  time_entries : (string * float) list list;
  time_per_engineer : (string, float) Hashtbl.t;
  work : Item.t list list;
}

val v :
  project:string ->
  objective:string ->
  title:string ->
  id:string option ->
  time_entries:(string * float) list list ->
  Item.t list list ->
  t

val dump : t Fmt.t
val merge : t -> t -> t
val compare : t -> t -> int
val update_from_master_db : t -> Masterdb.t -> t

type config = {
  show_engineers : bool;
  show_time : bool;
  show_time_calc : bool;
  include_krs : string list;
}

val items : config -> t -> Item.t list
val string_of_days : float -> string
