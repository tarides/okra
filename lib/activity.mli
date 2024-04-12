(*
 * Copyright (c) 2021 Patrick Ferris <pf341@patricoferris.com>
 * Copyright (c) 2021 Tim McGilchrist <timmcgil@gmail.com>
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
(** The type for your weekly activity *)

type project = { title : string; items : string list }

val make : projects:project list -> Get_activity.Contributions.t -> t
(** [make_activity ~projects activites] builds a new weekly activity *)

val repo_org :
  ?with_id:bool -> ?no_links:bool -> Format.formatter -> string -> unit
(** [report_org fs url] pretty-prints [url] in the form [repo/id]. *)

val pp_ga_item :
  ?gitlab:bool -> no_links:bool -> unit -> Get_activity.Contributions.item Fmt.t
(** [pp_ga_item ?gitlab ~no_links () ppf item] prints the get-activity item. See
    the description of [gitlab] and [no_links] in {!pp}. *)

val pp_activity :
  ?gitlab:bool ->
  no_links:bool ->
  unit ->
  Format.formatter ->
  Get_activity.Contributions.item list Get_activity.Contributions.Repo_map.t ->
  unit
(** [pp_activity ?gitlab ~no_links ()] can be used to print the underlying
    get-activity items. See the description of [gitlab] and [no_links] in {!pp}. *)

val pp :
  ?gitlab:bool -> ?no_links:bool -> print_projects:bool -> unit -> t Fmt.t
(** [pp ppf activity] formats a weekly activity into a template that needs some
    editing to get it into the correct format.

    [gitlab] controls whether the links are Gitlab links are not. The Github
    links get special formatting and can be formatted differently with
    [no_links].

    [no_links] controls rendering of markdown links to issues, reviews and prs.
    Defaults to [false] and longer url links. [true] for GitHub style shorter
    links eg project/repo#number

    [print_projects] controls wheter we display the list of projects at the
    beginning of the report. *)

module Gitlab : sig
  open Get_activity.Contributions

  val to_repo_map :
    Gitlab_t.events * (int * Gitlab_t.project_short) list ->
    item list Repo_map.t

  module Fetch
      (_ : Gitlab_s.Env)
      (_ : Gitlab_s.Time)
      (_ : Cohttp_lwt.S.Client) : sig
    module G : Gitlab_s.Gitlab

    val make_activity :
      token:G.Token.t ->
      before:string ->
      after:string ->
      (Gitlab_t.events * (int * Gitlab_t.project_short) list) G.Monad.t
  end
end
