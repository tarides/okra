(*
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

type conf
(** Configuration for get-activity *)

val make_conf : string -> conf
(** [make token] constructs a new configuration using the [token] *)

type t
(** The type for your weekly activity *)

val make : projects:string list -> Get_activity.Contributions.t -> t
(** [make_activity ~projects activites] builds a new weekly activity *)

val pp : t Fmt.t
(** [pp ppf activity] formats a weekly activity into a template that needs some
    editing to get it into the correct format. *)

val run :
  ?no_activity:bool ->
  cal:Calendar.t ->
  projects:string list ->
  conf ->
  (t, [ `Msg of string ]) Lwt_result.t
(** [run ?no_activity ~cal ~projects conf] produces an activity report for the
    week and year specified by [cal] using the configuration [conf]. The
    [projects] should be a list of KRs formatted as [<kr-title> (<kr-id>)].
    [no_activity] can disable any attempt to retrieve activities (leaving them
    empty), by default it is set to [false]. *)
