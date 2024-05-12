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

type t
(** The type for okra configurations *)

val default : t
(** A default configuration *)

val teams : t -> Okra.Team.t list

val projects : t -> Okra.Activity.project list
(** A user's list of activer projects *)

val footer : t -> string option
(** An optional footer to append to the end of your engineer reports *)

val okr_db : t -> string option
(** [okr_db] is the location of the OKR database. *)

val admin_dir : t -> string option
(** [admin_dir] is the location of the admin directory. *)

val gitlab_token : t -> string option
(** [gitlab_token] is the optional Gitlab token, if present your Gitlab activity
    will also be queried. *)

val work_days_in_a_week : t -> float option
(** [work_days_in_a_week] is an optional override for the number of days you work 
    in a given week, this is useful for contractors so [okra lint -e] doesn't report
    errors for working less than five days a week. *)

val load : string -> (t, [ `Msg of string ]) result
(** [load file] attempts to load a configuration from [file] *)

val default_file_path : string
(* [default_file_path] is the default file path of the Okra configuration. *)
