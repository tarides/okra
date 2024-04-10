(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
 * Copyright (c) 2021 Thomas Gazagnaire <thomas@gazagnaire.org>
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

type kind = Projects | Objectives | KRs
type t = { c : Common.t; md : Omd.doc; kind : kind }

open Okra

(* show largest work items first *)
let sort_by_days l =
  let aux (_, x) (_, y) = compare y x in
  List.sort aux l

let green = Fmt.(styled `Green string)
let cyan = Fmt.(styled `Cyan string)
let pp_days ppf d = Fmt.(styled `Bold Time.pp) ppf d

let print kind t =
  match kind with
  | Projects ->
      let projects =
        Aggregate.by_project t |> Hashtbl.to_seq |> List.of_seq |> sort_by_days
      in
      List.iter
        (fun (p_name, d) -> Fmt.pr "# %s: %a\n" p_name pp_days d)
        projects
  | Objectives ->
      let objectives =
        Aggregate.by_objective t
        |> Hashtbl.to_seq
        |> List.of_seq
        |> sort_by_days
      in
      List.iter
        (fun (o_name, d) ->
          let ps = Report.Objective.find_all t o_name in
          let o =
            String.concat "|"
              (List.map (fun (p, _) -> Report.Project.name p) ps)
          in
          Fmt.pr "## [%a] %s: %a\n"
            Fmt.(styled `Green string)
            o o_name pp_days d)
        objectives
  | KRs ->
      let krs =
        Aggregate.by_kr t |> Hashtbl.to_seq |> List.of_seq |> sort_by_days
      in
      List.iter
        (fun ((title, id), d) ->
          let id' =
            match id with KR.New_KR -> "New KR" | No_KR -> "No KR" | ID s -> s
          in
          let ps = Report.find t ~title ~id () in
          let pp ppf () =
            Fmt.list ~sep:(Fmt.any "|")
              (fun ppf kr ->
                Fmt.pf ppf "%a: %a" green kr.KR.project cyan kr.KR.objective)
              ppf ps
          in
          Fmt.pr "- [%a] %s (%s): %a\n" pp () title id' pp_days d)
        krs

let run conf =
  let okrs =
    Okra.Report.of_markdown
      ~ignore_sections:(Common.ignore_sections conf.c)
      ~include_sections:(Common.include_sections conf.c)
      conf.md
  in
  let okrs = Okra.Filter.apply (Common.filter conf.c) okrs in
  print conf.kind okrs

open Cmdliner

let kind =
  let i = Arg.info [ "kind" ] in
  let ks =
    Arg.enum
      [ ("projects", Projects); ("objectives", Objectives); ("krs", KRs) ]
  in
  Arg.(value (opt ks KRs i))

let term =
  let open Let_syntax_cmdliner in
  let+ kind = kind and+ c = Common.term and+ md = Common.input in
  run { c; md; kind }

let cmd =
  let info = Cmd.info "stats" ~doc:"show OKR statistics" in
  Cmd.v info term
