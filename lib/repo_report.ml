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

let ( let* ) = Result.bind

let owner_name s =
  match Astring.String.cut ~sep:"/" s with
  | Some t -> t
  | None -> Fmt.failwith "%s: failed to get owner and name" s

module U = Yojson.Safe.Util

let ( / ) a b = U.member b a
let ( // ) a b = try Some (U.member b a) with _ -> None

let underscore s =
  String.split_on_char '-' s
  |> String.concat "_"
  |> String.split_on_char '.'
  |> String.concat "_"

module Issue = struct
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

  let parse json =
    let cursor = json / "cursor" |> U.to_string in
    let json = json / "node" in
    let author = Option.map U.to_string @@ (json / "author" // "login") in
    let url = json / "url" |> U.to_string in
    let body = json / "body" |> U.to_string in
    let title = json / "title" |> U.to_string in
    let closed = json / "closed" |> U.to_bool in
    let created_at = json / "createdAt" |> U.to_string in
    let closed_at = json / "closedAt" |> U.to_string_option in
    { author; cursor; title; url; body; closed; closed_at; created_at }

  let pp ~with_names ~with_times ~with_descriptions ppf
      { author; title; url; created_at; body; _ } =
    let pp_user ppf = Fmt.pf ppf "@%s" in
    let pp_created_at ppf = Fmt.pf ppf " (created/merged: %s)" in
    let pp_author ppf = Fmt.pf ppf " by %a" pp_user in
    Fmt.(
      pf ppf " - [%s](%s)%a%a\n   %a\n" title url (option pp_author)
        (if not with_names then None else author)
        (option pp_created_at)
        (if not with_times then None else Some created_at)
        (option string)
        (if not with_descriptions then None else Some body))

  let query =
    {| issues (last:100, orderBy: { direction: ASC, field: CREATED_AT }, before: $before_issue) {
    edges {
      cursor
      node {
        author {
          login
        }
        url
        title
        body
        closed
        closedAt
        createdAt
      }
    }
  } |}
end

module PR = struct
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

  let parse json =
    let cursor = json / "cursor" |> U.to_string in
    let json = json / "node" in
    let author = Option.map U.to_string @@ (json / "author" // "login") in
    let url = json / "url" |> U.to_string in
    let body = json / "body" |> U.to_string in
    let title = json / "title" |> U.to_string in
    let closed = json / "closed" |> U.to_bool in
    let created_at = json / "createdAt" |> U.to_string in
    let closed_at = json / "closedAt" |> U.to_string_option in
    let is_draft = json / "isDraft" |> U.to_bool in
    let merged_at = json / "mergedAt" |> U.to_string_option in
    let merged_by = Option.map U.to_string @@ (json / "mergedBy" // "login") in
    let reviewers =
      json / "reviews" / "nodes"
      |> U.to_list
      |> List.map (fun v -> v / "author" / "login" |> U.to_string)
      |> List.sort_uniq String.compare
    in
    {
      author;
      url;
      cursor;
      body;
      title;
      closed;
      closed_at;
      created_at;
      is_draft;
      merged_at;
      merged_by;
      reviewers;
    }

  let split_by_status ts =
    let split (opened, merged) t =
      if Option.is_some t.merged_at then (opened, t :: merged)
      else (t :: opened, merged)
    in
    List.fold_left split ([], []) ts

  let pp ~with_names ~with_times ~with_descriptions ppf
      { author; title; url; created_at; merged_at; reviewers; body; _ } =
    let pp_user ppf u = Fmt.pf ppf "[@%s](https://github.com/%s)" u u in
    let pp_created_at ppf = Fmt.pf ppf " (created/merged: %s)" in
    let pp_author ppf = Fmt.pf ppf " by %a" pp_user in
    let reviewers =
      List.filter (fun x -> not (String.equal "github-actions" x)) reviewers
    in
    if reviewers = [] || not with_names then
      Fmt.(
        pf ppf " - [%s](%s)%a%a\n   %a\n" title url (option pp_author)
          (if not with_names then None else author)
          (option pp_created_at)
          (if not with_times then None
           else if merged_at = None then Some created_at
           else merged_at)
          (option string)
          (if not with_descriptions then None else Some body))
    else
      Fmt.(
        pf ppf " - [%s](%s) by %a\n\n   (%s, reviewed by: %a)\n   %a\n" title
          url pp_user
          (Option.value ~default:"No author" author)
          (Option.value ~default:("created: " ^ created_at)
             (Option.map (( ^ ) "merged: ") merged_at))
          Fmt.(list ~sep:(fun ppf _ -> Fmt.pf ppf ", ") pp_user)
          reviewers (option string)
          (if not with_descriptions then None else Some body))

  (* The Gihub Graphql API doesn't let you specify a from and to for accessing
     PRs or issues so we have paginate our way back to from if that is
     necessary. The way to do this is with the cursor *)
  let query =
    {| pullRequests (last:100, orderBy: { direction: ASC, field: CREATED_AT }, before: $before_pr) {
    edges {
      cursor
      node {
        author {
          login
        }
        url
        title
        body
        closed
        closedAt
        createdAt
        isDraft
        merged
        mergedAt
        mergedBy {
          login
        }
        reviews (last: 100) {
          nodes {
            author {
              login
            }
          }
        }
      }
    }
  } |}
end

type data = {
  org : string;
  repo : string;
  description : string option;
  issues : Issue.t list;
  prs : PR.t list;
}

let project_query ~owner name =
  Fmt.str
    {| %s: repository(owner: "%s", name: "%s") {
    description
    %s
    %s
  } |}
    (underscore name) owner name Issue.query PR.query

let query projects =
  Fmt.str {| query($before_issue: String, $before_pr: String) {
  %s
} |}
    (List.map (fun (owner, name) -> project_query ~owner name) projects
    |> String.concat "\n")

let pp_data ~with_names ~with_times ~with_descriptions ppf (data : data) =
  let pp_prs ppf prs =
    let opened, merged = PR.split_by_status prs in
    Fmt.pf ppf
      "#### Opened (and not merged in same time frame)\n\n\
       %a\n\n\
       #### Merged\n\n\
       %a"
      Fmt.(list (PR.pp ~with_names ~with_times ~with_descriptions))
      (List.sort
         (fun v1 v2 -> String.compare v1.PR.created_at v2.created_at)
         opened)
      Fmt.(list (PR.pp ~with_names ~with_times ~with_descriptions))
      (List.sort
         (fun v1 v2 ->
           String.compare (Option.get v1.PR.merged_at) (Option.get v2.merged_at))
         merged)
  in
  Fmt.pf ppf
    "## [%s](https://github.com/%s/%s)\n\
     %s\n\n\
     ### Pull Requests\n\n\
     %a\n\n\
     ### Issues\n\n\
     %a"
    data.repo data.org data.repo
    (Option.value ~default:"No description" data.description)
    pp_prs data.prs
    Fmt.(list (Issue.pp ~with_names ~with_times ~with_descriptions))
    (List.sort
       (fun v1 v2 -> String.compare v1.Issue.created_at v2.created_at)
       data.issues)

module Project_map = Map.Make (String)

type t = data Project_map.t

let pp ?(with_names = false) ?(with_times = false) ?(with_descriptions = false)
    ppf t =
  Project_map.bindings t
  |> List.map snd
  |> Fmt.(
       pf ppf "%a" (list (pp_data ~with_names ~with_times ~with_descriptions)))

let parse_data (from, to_) org repo json =
  let project = json / "data" / underscore repo in
  let description = project / "description" |> U.to_string_option in
  let issues =
    project / "issues" / "edges" |> U.to_list |> List.map Issue.parse
  in
  let prs =
    project / "pullRequests" / "edges" |> U.to_list |> List.map PR.parse
  in
  (* We might need to fetch more PRs or issues, so we provide the cursor to
     paginate further back. Somewhat a limitation in the Github API *)
  let need_more_prs =
    match prs with
    | { created_at; cursor; _ } :: _ ->
        if from < created_at then Some (`String cursor) else None
    | [] -> None
  in
  let need_more_issues =
    match issues with
    | { created_at; cursor; _ } :: _ ->
        if from < created_at then Some (`String cursor) else None
    | [] -> None
  in
  let filter_prs from to_ { PR.created_at; merged_at; _ } =
    let time = Option.value ~default:created_at merged_at in
    time >= from && time <= to_
  in
  let filter_issues from to_ { Issue.created_at; _ } =
    created_at >= from && created_at <= to_
  in
  ( need_more_prs,
    need_more_issues,
    {
      org;
      repo;
      description;
      issues = List.filter (filter_issues from to_) issues;
      prs = List.filter (filter_prs from to_) prs;
    } )

let add_list s v t = Project_map.add s v t

module Fetch = Get_activity.Graphql

let request ?before_pr ?before_issue ~period:_ ~token query =
  let variables =
    [
      ("before_pr", Option.value ~default:`Null before_pr);
      ("before_issue", Option.value ~default:`Null before_issue);
    ]
  in
  Fetch.request ~token ~variables ~query ()

let exec req = Fetch.exec req

let merge_data datas =
  let first, rest =
    match datas with x :: rest -> (x, rest) | _ -> failwith "No data found!"
  in
  let data =
    List.fold_left
      (fun d { prs; issues; _ } ->
        { d with prs = d.prs @ prs; issues = d.issues @ issues })
      first rest
  in
  {
    data with
    prs =
      List.sort_uniq (fun v1 v2 -> String.compare v1.PR.title v2.title) data.prs;
    issues =
      List.sort_uniq
        (fun v1 v2 -> String.compare v1.Issue.title v2.title)
        data.issues;
  }

let get ~period ~token repos =
  let repos = List.map owner_name repos in
  let* json = exec @@ request ~period ~token (query repos) in
  let rec parse acc period org name json =
    match parse_data period org name json with
    | None, None, data ->
        if acc = [] then Ok data else Ok (merge_data (data :: acc))
    | before_pr, before_issue, data ->
        let* json =
          (* TODO: we always ask for all the data even if we don't need more
             issues when searching for more PRs (and for every repository). For
             queries not too far in the past, and with not too many repos per
             query this is okay but in the long-term it might be good to drop
             parts of the query when they are done. *)
          exec @@ request ?before_pr ?before_issue ~period ~token (query repos)
        in
        parse (data :: acc) period org name json
  in
  let map = Project_map.empty in
  List.fold_left
    (fun m (org, name) ->
      let* m = m in
      let* v = parse [] period org name json in
      Ok (add_list name v m))
    (Ok map) repos
