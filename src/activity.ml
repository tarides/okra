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

open Lwt.Infix

module Gql = struct
  type t = {
    query : string;
    variables : (string * Yojson.Safe.t) list option;
    token : string;
    endpoint : Uri.t;
  }

  let raw_fetch (k : t) =
    let body =
      `Assoc
        (("query", `String k.query)
         ::
         (match k.variables with
         | None -> []
         | Some v -> [ ("variables", `Assoc v) ]))
      |> Yojson.Safe.to_string
      |> Cohttp_lwt.Body.of_string
    in
    let headers =
      Cohttp.Header.init_with "Authorization" ("bearer " ^ k.token)
    in
    Cohttp_lwt_unix.Client.post ~headers ~body k.endpoint
    >>= fun (resp, body) ->
    Cohttp_lwt.Body.to_string body >|= fun body ->
    match Cohttp.Response.status resp with
    | `OK -> Ok body
    | err ->
        Fmt.error_msg "@[<v2>Error performing GraphQL query: %s@,%s@]"
          (Cohttp.Code.string_of_status err)
          body
end

type conf = { token : string }

let make_conf token = { token }

let pp_last_week username ppf projects =
  let pp_project ppf t =
    Fmt.pf ppf "- %s\n  - @%s (<X> days)\n  - Work Item 1" t username
  in
  Fmt.pf ppf "%a" Fmt.(list ~sep:(cut ++ cut) pp_project) projects

let pp_activity ppf activity =
  let open Get_activity.Contributions in
  let pp_item ppf item = Fmt.pf ppf "  - %a" pp_title item in
  let bindings = Repo_map.bindings activity in
  let pp_binding ppf (_repo, items) =
    Fmt.pf ppf "%a" Fmt.(list pp_item) items
  in
  Fmt.pf ppf "%a" Fmt.(list pp_binding) bindings

type t = { projects : string list; activity : Get_activity.Contributions.t }

let make ~projects activity = { projects; activity }

let pp ppf { projects; activity = { username; activity } } =
  Fmt.pf ppf
    {|# Projects

%a

# Last Week

%a

# Activity (move these items to last week)

%a
|}
    Fmt.(list (fun ppf s -> Fmt.pf ppf "- %s" s))
    projects (pp_last_week username) projects pp_activity activity

let run ?(no_activity = false) ~cal ~projects { token } =
  if no_activity then
    Lwt.return
      (Ok
         {
           projects;
           activity =
             {
               username = "<USERNAME>";
               activity = Get_activity.Contributions.Repo_map.empty;
             };
         })
  else
    let from, to_ = Calendar.github_week cal in
    let variables = [ ("from", `String from); ("to", `String to_) ] in
    let fetch_params =
      Gql.
        {
          query = Get_activity.Contributions.query;
          variables = Some variables;
          endpoint = Get_activity.Graphql.graphql_endpoint;
          token;
        }
    in
    Gql.raw_fetch fetch_params >|= Result.map Yojson.Safe.from_string
    >>= fun json ->
    match json with
    | Ok json ->
        let activity = Get_activity.Contributions.of_json ~from json in
        Lwt.return (Ok { projects; activity })
    | Error _ as e -> Lwt.return e
