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

module Issue : sig
  type t = {
    author : string option;
    title : string;
    cursor : string;
    url : string;
    body : string;
    closed : bool;
    closed_at : string option;
    created_at : string;
  }

  val parse : Yojson.Safe.t -> t
  (** Parses the json received from the Github Graphql API *)

  val pp :
    with_names:bool -> with_times:bool -> with_descriptions:bool -> t Fmt.t
  (** Prints the issue to a markdown format *)
end

module PR : sig
  type t = {
    author : string option;
    cursor : string;
    url : string;
    title : string;
    body : string;
    closed : bool;
    closed_at : string option;
    created_at : string;
    is_draft : bool;
    merged_at : string option;
    merged_by : string option;
    reviewers : string list;
  }

  val split_by_status : t list -> t list * t list
  (** Splits a list of PRs into two lists [opened, merged] *)

  val parse : Yojson.Safe.t -> t
  (** Parses the json received from the Github Graphql API *)

  val pp :
    with_names:bool -> with_times:bool -> with_descriptions:bool -> t Fmt.t
  (** Prints the issue to a markdown format *)

  val query : string
  (** Graphql query for PRs *)
end

type data = {
  org : string;
  repo : string;
  description : string option;
  issues : Issue.t list;
  prs : PR.t list;
}
(** A type for the data about a single repository *)

module Project_map : Map.S with type key := string

type t = data Project_map.t
(** A map from repositories to their PR/issue data *)

val get :
  period:string * string ->
  token:string ->
  string list ->
  (data Project_map.t, [ `Msg of string ]) result
(** [get ~period ~token repos] gets the information for [repos] over the
    specified [period] using the Github [token] *)

val pp :
  ?with_names:bool -> ?with_times:bool -> ?with_descriptions:bool -> t Fmt.t
(** Prints a markdown formatted view of the data *)
