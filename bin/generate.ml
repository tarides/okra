(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
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

open Okra
open Cmdliner
module Cal = CalendarLib.Calendar

let ( let* ) = Result.bind

(* The kind of report we are generating - engineer: a report for an individual
   engineer - reposiories: 1 or more repository contributions *)

type kind = Engineer | Repository

let kind_term =
  Arg.value
  @@ Arg.opt
       Arg.(enum [ ("engineer", Engineer); ("repository", Repository) ])
       Engineer
  @@ Arg.info ~doc:"The kind of report you would like to generate." ~docv:"KIND"
       [ "k"; "kind" ]

let repositories =
  Arg.value
  @@ Arg.pos_all Arg.string []
  @@ Arg.info
       ~doc:
         "A list of repositories to generate reports for (only for \
          kind=repository)"
       ~docv:"REPOSITORIES" []

let no_activity =
  Arg.value
  @@ Arg.flag
  @@ Arg.info
       ~doc:
         "The --no-activity flag will disable any attempt to generate activity \
          reports from Github"
       ~docv:"NO-ACTIVITY" [ "no-activity" ]

let print_projects =
  let info =
    Arg.info [ "print-projects" ]
      ~doc:"Print the list of projects in the generated report"
  in
  Arg.value (Arg.flag info)

let interactive =
  let info =
    Arg.info [ "interactive"; "i" ]
      ~doc:
        "Create the file containing the activity report, and open it for the \
         user to edit. Upon close, commit the file."
  in
  Arg.value (Arg.flag info)

let with_repositories_term =
  Arg.value
  @@ Arg.opt Arg.(list string) []
  @@ Arg.info
       ~doc:
         "Specify a list of Github repositories (e.g. ocaml/opam-repository) \
          to get your merges from. This is probably only useful for people who \
          spend time merging PRs but not explicitly reviewing them so the \
          activity won't appear normally (or creating the PR)"
       [ "include-repositories" ]

let user : Get_activity.User.t Term.t =
  let str_parser, str_printer = Arg.string in
  let parser x =
    match str_parser x with
    | `Ok x -> `Ok (Get_activity.User.User x)
    | `Error e -> `Error e
  in
  let printer fs = function
    | Get_activity.User.Viewer -> str_printer fs "viewer"
    | User x -> str_printer fs x
  in
  let user_conv = (parser, printer) in
  let doc = Arg.info ~doc:"User name" [ "user" ] in
  Arg.(value & opt user_conv Viewer & doc)

(* Get activity configuration *)
let home =
  match Sys.getenv_opt "HOME" with
  | None -> Fmt.failwith "$HOME is not set!"
  | Some dir -> dir

let default_token_file =
  let ( / ) = Filename.concat in
  home / ".github" / "github-activity-token"

let token =
  Arg.value
  @@ Arg.opt Arg.file default_token_file
  @@ Arg.info
       ~doc:
         "The path to a file containing your github token, defaults to \
          ~/.github/github-activity-token"
       ~docv:"TOKEN" [ "token" ]

module User_fetch = Get_activity.Contributions
module Repo_fetch = Okra.Repo_report

module Time = struct
  let now = Unix.gettimeofday
  let sleep = Lwt_unix.sleep
end

module Env = struct
  let debug = try Unix.getenv "GITLAB_DEBUG" <> "0" with _ -> false

  let gitlab_uri =
    try Unix.getenv "GITLAB_URL" with _ -> "https://gitlab.com/api/v4"
end

module Gitlab = Activity.Gitlab.Fetch (Env) (Time) (Cohttp_lwt_unix.Client)

let fetch ~token ~period =
  let after, before = Okra.Calendar.to_gitlab period in
  let token = Gitlab.G.Token.of_string token in
  Gitlab.make_activity ~token ~before ~after

let editor () =
  let ( or ) x y = Result.value x ~default:y in
  Bos.OS.Env.req_var "VISUAL" or Bos.OS.Env.req_var "EDITOR" or "vi"

let write_and_commit ~repo ~week ~year ~user pp =
  let* admin_dir = repo in
  let file =
    Fpath.(
      v admin_dir / "weekly" / Fmt.str "%4d" year / Fmt.str "%02i" week / user
      |> add_ext "md")
  in
  let* () = Bos.OS.File.delete file in
  let* () = Bos.OS.File.writef file "%a%!" pp () in
  let editor = editor () in
  let* () = Bos.OS.Cmd.run @@ Bos.Cmd.(v editor % p file) in
  let* res = Bos.OS.File.with_ic file (fun ic () -> Okra.Lint.lint ic) () in
  let* () =
    Result.map_error
      (fun errors ->
        List.iter
          (fun e ->
            List.iter print_endline
              (Okra.Lint.short_messages_of_error (Fpath.to_string file) e))
          errors;
        `Msg "linting failed, aborting.")
      res
  in
  let git_cmd = Bos.Cmd.(v "git" % "-C" % p (Fpath.v admin_dir)) in
  let* () = Bos.OS.Cmd.run @@ Bos.Cmd.(git_cmd % "add" % p file) in
  let msg = Format.sprintf "%s week %i" user week in
  let* () =
    Bos.OS.Cmd.run @@ Bos.Cmd.(git_cmd % "commit" % p file % "-m" % msg)
  in
  Ok ()

let run_engineer ppf conf cal projects token no_activity no_links
    with_repositories user print_projects repo interactive =
  let period = Calendar.to_iso8601 cal in
  let week = Calendar.week cal in
  let year = Calendar.year cal in
  let* activity, _ =
    if no_activity then
      let username =
        match user with Get_activity.User.Viewer -> "<USERNAME>" | User u -> u
      in
      Ok (Get_activity.Contributions.{ username; activity = Repo_map.empty }, [])
    else
      let contributions () =
        let* fetch =
          Get_activity.Graphql.exec @@ User_fetch.request ~period ~user ~token
        in
        let* report =
          (* When a user specifies `with_repositories` we also fetch reports
             from these repositories and filter the PRs made over the same time
             period that were merged by the user returned by fetching the
             original get-activity. *)
          if with_repositories = [] then Ok Repo_report.Project_map.empty
          else Repo_fetch.get ~period ~token with_repositories
        in
        let* contribs =
          Get_activity.Contributions.of_json ~period ~user fetch
        in
        let merges =
          let bindings = Repo_report.Project_map.bindings report in
          List.map
            (fun (_, v) ->
              List.filter
                (fun pr -> Some contribs.username = pr.Repo_report.PR.merged_by)
                v.Repo_report.prs)
            bindings
        in
        Ok (contribs, List.concat merges)
      in
      contributions ()
  in
  let gitlab_activity =
    let open Gitlab.G.Monad in
    match Conf.gitlab_token conf with
    | Some token ->
        let main () =
          let+ events = fetch ~token ~period:cal in
          Activity.Gitlab.to_repo_map events
        in
        Lwt_main.run @@ Gitlab.G.Monad.run (main ())
    | None -> Get_activity.Contributions.Repo_map.empty
  in
  let from, to_ = Calendar.range cal in
  let format_date f = CalendarLib.Printer.Date.fprint "%0Y/%0m/%0d" f in
  let header =
    Fmt.str "%s week %i: %a -- %a" activity.username week format_date from
      format_date to_
  in
  let pp_footer ppf conf = Fmt.(pf ppf "\n\n%a" string conf) in
  let user = activity.username in
  let activity = Activity.make ~projects activity in
  let pp ppf () =
    Fmt.pf ppf "%s\n\n%a%a%a%!" header
      (Activity.pp ~no_links ~print_projects ())
      activity
      (Activity.pp_activity ~gitlab:true ~no_links:false ())
      gitlab_activity
      Fmt.(option pp_footer)
      (Conf.footer conf)
  in
  if interactive then write_and_commit ~repo ~week ~year ~user pp
  else (
    pp ppf ();
    Ok ())

let get_or_error = function
  | Ok v -> v
  | Error (`Msg m) ->
      Fmt.epr "%s" m;
      exit 1

let run_monthly ppf cal repos token with_names with_times with_descriptions =
  let from, to_ = Calendar.range cal in
  let format_date f = CalendarLib.Printer.Date.fprint "%0Y/%0m/%0d" f in
  let period = Calendar.to_iso8601 cal in
  let* projects = Repo_fetch.get ~period ~token repos in
  Fmt.pf ppf "# Reports (%a - %a)\n\n%a%!" format_date from format_date to_
    (Repo_report.pp ~with_names ~with_times ~with_descriptions)
    projects;
  Ok ()

let run ppf cal conf token no_activity no_links with_names with_times
    with_descriptions with_repositories repos user print_projects repo
    interactive = function
  | Engineer ->
      run_engineer ppf conf cal (Conf.projects conf) token no_activity no_links
        with_repositories user print_projects repo interactive
  | Repository ->
      run_monthly ppf cal repos token with_names with_times with_descriptions

let term =
  let open Let_syntax_cmdliner in
  let+ c = Common.term
  and+ token_file = token
  and+ no_activity = no_activity
  and+ print_projects = print_projects
  and+ with_repositories = with_repositories_term
  and+ kind = kind_term
  and+ user = user
  and+ interactive = interactive
  and+ repos = repositories in
  let token =
    (* If [no_activity] is specfied then the token will not be used, don't try
       to load the file in that case *)
    if no_activity then ""
    else get_or_error @@ Get_activity.Token.load token_file
  in
  let cal = Common.date c in
  let conf = Common.conf c in
  let no_links = not (Common.with_links c) in
  let with_names = Common.with_names c in
  let with_times = Common.with_days c in
  let with_descriptions = Common.with_description c in
  let ppf = Format.formatter_of_out_channel (Common.output c) in
  let repo = Common.repo c in
  run ppf cal conf token no_activity no_links with_names with_times
    with_descriptions with_repositories repos user print_projects repo
    interactive kind

let cmd =
  let info =
    Cmd.info "generate"
      ~doc:"Generate an initial weekly report based on Github activity"
      ~man:
        [
          `S Manpage.s_description;
          `P
            "The generate command produces markdown reports using activity \
             from Github. There are two kinds of report that can be generated: \
             an engineer report and a repository report. The former shows your \
             individual activity for a given period and the latter shows \
             activity for a given set of repositories.";
          `P
            "See the options below for changing things like which week to \
             query for and where to find your token. To generate a token see \
             the README at https://github.com/talex5/get-activity.";
        ]
  in
  Cmd.v info (Term.term_result term)
