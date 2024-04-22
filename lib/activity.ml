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

type project = { title : string; items : string list }

let title { title; _ } = title

type t = { projects : project list; activity : Get_activity.Contributions.t }

let pp_last_week username ppf projects =
  let pp_items ppf t =
    let t = if t = [] then [ "Work Item 1" ] else t in
    Fmt.(pf ppf "%a" (list (fun ppf s -> Fmt.pf ppf "  - %s" s))) t
  in
  let pp_project ppf { title; items } =
    Fmt.pf ppf "- %s\n  - %a (<X> days)\n%a@." title (User.pp ~with_link:false)
      username pp_items items
  in
  Fmt.pf ppf "%a" Fmt.(list ~sep:(cut ++ cut) pp_project) projects

let repo_org ?(with_id = false) ?(no_links = false) f s =
  let remove_hash s =
    match String.split_on_char '#' s with
    | [ i ] -> i (* Normal PR or Issue ids *)
    | i :: _ -> i (* Extracted from PR reviews *)
    | _ -> failwith "Malformed URL trying to get id number"
  in
  match String.split_on_char '/' s |> List.rev with
  (* URLs with ids have the form (in reverse) <id>/<kind>/<repo>/<org>/... *)
  | i :: _ :: repo :: org :: _ when with_id ->
      if no_links then Fmt.pf f "(%s/%s#%s)" org repo i
      else Fmt.pf f "[%s/%s#%s](%s)" org repo (remove_hash i) s
  (* For now the only kind like this are new repository creations *)
  | repo :: org :: _ -> Fmt.pf f "[%s/%s](%s)" org repo s
  | _ -> Fmt.failwith "Malformed URL %S" s

let pp_ga_item ?(gitlab = false) ~no_links sub_items f
    (t : Get_activity.Contributions.item) =
  match gitlab with
  | true -> (
      match t.kind with
      | `PR -> Fmt.pf f "Opened PR (Gitlab): %s %s" t.title t.url
      | `Issue -> Fmt.pf f "Opened issue (Gitlab): %s %s" t.title t.url
      | _ -> ())
  | false -> (
      match t.kind with
      | `Issue ->
          Fmt.pf f "Opened issue: %s %a" t.title
            (repo_org ~with_id:true ~no_links)
            t.url
      | `PR ->
          let merged =
            List.exists
              (fun x -> x.Get_activity.Contributions.kind = `Merge)
              sub_items
          in
          let status = if merged then "Opened and merged" else "Opened" in
          Fmt.pf f "%s PR: %s %a" status t.title
            (repo_org ~with_id:true ~no_links)
            t.url
      | `Comment `Issue ->
          Fmt.pf f "Commented (%i) on issue: %s %a"
            (List.length sub_items + 1)
            t.title
            (repo_org ~with_id:true ~no_links)
            t.url
      | `Comment `PR ->
          Fmt.pf f "Commented (%i) on PR: %s %a"
            (List.length sub_items + 1)
            t.title
            (repo_org ~with_id:true ~no_links)
            t.url
      | `Review s ->
          Fmt.pf f "%s PR: %s %a"
            (String.capitalize_ascii @@ String.lowercase_ascii s)
            t.title
            (repo_org ~with_id:true ~no_links)
            t.url
      | `Merge ->
          Fmt.pf f "Merged PR: %s %a" t.title
            (repo_org ~with_id:true ~no_links)
            t.url
      | `New_repo ->
          Fmt.pf f "Created repository %a"
            (repo_org ~with_id:false ~no_links)
            t.url)

let order_item_kind = function
  | `New_repo -> 0
  | `Issue -> 1
  | `PR -> 2
  | `Merge -> 3
  | `Review _ -> 4
  | `Comment `PR -> 5
  | `Comment `Issue -> 56

let sort_items (x : Get_activity.Contributions.item)
    (y : Get_activity.Contributions.item) =
  match Int.compare (order_item_kind x.kind) (order_item_kind y.kind) with
  | 0 -> String.compare x.date y.date
  | cmp -> cmp

let root_of_url url =
  match String.split_on_char '#' url with
  | [ root_url ] -> root_url
  | [ root_url; _comment_suffix ] -> root_url
  | _ ->
      Logs.warn (fun m -> m "invalid url: %s" url);
      url

let contains match_kind url ((c : Get_activity.Contributions.item), _) =
  match_kind c.kind && String.equal (root_of_url url) (root_of_url c.url)

let add_to_maybe_another_item ~can_add_to item acc =
  let found, rest =
    List.partition (contains can_add_to item.Get_activity.Contributions.url) acc
  in
  match found with
  (* the comment is stored as a root item *)
  | [] -> (item, []) :: rest
  (* the comment is stored as a subitem of another item *)
  | (root, subitems) :: _ -> (root, item :: subitems) :: rest

let build_tree activity =
  Get_activity.Contributions.Repo_map.map
    (fun items ->
      List.sort sort_items items
      |> List.fold_left
           (fun acc item ->
             match item.Get_activity.Contributions.kind with
             | `Issue | `PR | `New_repo | `Review _ -> (item, []) :: acc
             | `Merge ->
                 add_to_maybe_another_item item acc ~can_add_to:(function
                   | `PR -> true
                   | _ -> false)
             | `Comment `PR ->
                 add_to_maybe_another_item item acc ~can_add_to:(function
                   | `PR | `Review _ | `Merge | `Comment `PR -> true
                   | _ -> false)
             | `Comment `Issue ->
                 add_to_maybe_another_item item acc ~can_add_to:(function
                   | `Issue | `Comment `Issue -> true
                   | _ -> false))
           []
      |> List.rev)
    activity

let pp_activity ?(gitlab = false) ~no_links () ppf activity =
  let open Get_activity.Contributions in
  let activity = build_tree activity in
  let pp_item ppf (item, sub_items) =
    Fmt.pf ppf "  - %a" (pp_ga_item ~gitlab ~no_links sub_items) item
  in
  let bindings = Repo_map.bindings activity in
  let pp_binding ppf (_repo, items) =
    Fmt.pf ppf "%a" Fmt.(list pp_item) items
  in
  Fmt.pf ppf "%a" Fmt.(list pp_binding) bindings

let make ~projects activity = { projects; activity }

let pp_projects ~print_projects ppf projects =
  if print_projects then
    let newline fs () = Fmt.pf fs "@\n" in
    Fmt.pf ppf {|# Projects

%a

|}
      Fmt.(list ~sep:newline (fun ppf s -> Fmt.pf ppf "- %s" s))
      (List.map title projects)

let pp ?(gitlab = false) ?(no_links = false) ~print_projects () ppf
    { projects; activity = { username; activity } } =
  pp_projects ~print_projects ppf projects;
  Fmt.pf ppf {|# Last Week

%a
# Activity (move these items to last week)

%a
|}
    (pp_last_week username) projects
    (pp_activity ~gitlab ~no_links ())
    activity

(* The equivalent get-activity style information for Gitlab is in the Events
   API *)
module Gitlab = struct
  open Get_activity.Contributions

  let make_pull_request url (v : Gitlab_t.event) =
    {
      repo = string_of_int v.event_project_id;
      kind = `PR;
      date = Gitlab_json.DateTime.unwrap v.event_created_at;
      url;
      title =
        Fmt.str "%a %s"
          Fmt.(option string)
          (Option.map Gitlab_j.string_of_event_action_name v.event_action_name)
          (Option.value ~default:"Gitlab PR" v.event_target_title);
      body = Option.value ~default:"Gitlab PR" v.event_target_title;
    }

  let make_issue url (v : Gitlab_t.event) =
    {
      repo = string_of_int v.event_project_id;
      kind = `Issue;
      date = Gitlab_json.DateTime.unwrap v.event_created_at;
      url;
      title = Option.value ~default:"Gitlab Issue" v.event_target_title;
      body = Option.value ~default:"Gitlab Issue" v.event_target_title;
    }

  let to_repo_map :
      Gitlab_t.events * (int * Gitlab_t.project_short) list ->
      item list Repo_map.t =
   fun (evs, projects) ->
    let to_ga_item (ev : Gitlab_t.event) =
      let project = List.assoc_opt ev.event_project_id projects in
      match (project, ev.event_target_type) with
      | Some project, Some `MergeRequest ->
          let url =
            Fmt.str "%s/-/merge_requests/%a" project.project_short_web_url
              Fmt.(option int)
              ev.event_target_iid
          in
          Some (make_pull_request url ev)
      | Some project, Some `Issue ->
          let url =
            Fmt.str "%s/-/issues/%a" project.project_short_web_url
              Fmt.(option int)
              ev.event_target_iid
          in
          Some (make_issue url ev)
      | _ -> None
    in
    let lst = List.filter_map to_ga_item evs in
    let repo = Repo_map.empty in
    List.fold_left
      (fun map item ->
        match Repo_map.find_opt "Gitlab" map with
        | Some items -> Repo_map.add "Gitlab" (item :: items) map
        | None -> Repo_map.add "Gitlab" [ item ] map)
      repo lst

  module Fetch
      (Env : Gitlab_s.Env)
      (Time : Gitlab_s.Time)
      (CL : Cohttp_lwt.S.Client) =
  struct
    module G = Gitlab_core.Make (Env) (Time) (CL)
    open G.Monad

    let map_s f l =
      let open G.Monad in
      let rec inner acc = function
        | [] -> List.rev acc |> return
        | hd :: tl -> f hd >>= fun r -> inner (r :: acc) tl
      in
      inner [] l

    let get_project ~token i =
      let+ res = G.Project.by_id ~token ~project_id:i () in
      (i, Option.get @@ G.Response.value res)

    let make_activity ~token ~before ~after =
      let open G.Monad in
      let* res = G.Event.all ~token ~before ~after () in
      let events = G.Response.value res in
      let ids =
        List.map (fun (v : Gitlab_t.event) -> v.event_project_id) events
        |> List.sort_uniq Int.compare
      in
      map_s (get_project ~token) ids >>= fun ids -> return (events, ids)
  end
end
