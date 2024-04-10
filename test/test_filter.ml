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

open Okra
module T = Okra.Time

let p1 = "Project 1"
let p2 = "Project 2"
let o1 = "O1"
let o2 = "O2"
let t1 = "title1"
let t2 = "title2"
let t3 = "title3"
let e1 = "foo"
let e2 = "bar"
let e3 = "john"
let te1 = [ [ (e1, T.days 1.) ]; [ (e1, T.days 2.); (e2, T.days 2.) ] ]
let te2 = [ [ (e1, T.days 10.) ] ]
let te3 = [ [ (e2, T.days 10.) ]; [ (e3, T.days 5.) ] ]
let id2 = "Id2"
let id3 = "ID3"

let kr1 =
  KR.v ~project:p1 ~objective:o1 ~title:t1 ~id:KR.New_KR ~time_entries:te1 []

let kr2 =
  KR.v ~project:p2 ~objective:o2 ~title:t2 ~id:(ID id2) ~time_entries:te2 []

let kr3 =
  KR.v ~project:p2 ~objective:o2 ~title:t3 ~id:(ID id3) ~time_entries:te3 []

let report () = Okra.Report.of_krs [ kr1; kr2; kr3 ]

let filter ?include_projects ?exclude_projects ?include_objectives
    ?exclude_objectives ?include_krs ?exclude_krs ?include_engineers
    ?exclude_engineers t =
  let f =
    Okra.Filter.v ?include_projects ?exclude_projects ?include_objectives
      ?exclude_objectives ?include_krs ?exclude_krs ?include_engineers
      ?exclude_engineers ()
  in
  Okra.Filter.apply f t

let test_include_projects () =
  let t = report () in
  let t1 = filter t ~include_projects:[ p1 ] in
  Alcotest.(check int) "include project 1" 1 (List.length (Report.all_krs t1));
  let t2 = filter t ~include_projects:[ p1; p2 ] in
  Alcotest.(check int)
    "include projects 1,2" 3
    (List.length (Report.all_krs t2))

let test_exclude_projects () =
  let t = report () in
  let t1 = filter t ~exclude_projects:[ p1 ] in
  Alcotest.(check int) "exclude project 1" 2 (List.length (Report.all_krs t1));
  let t1 = filter t ~include_projects:[ p2 ] ~exclude_projects:[ p1 ] in
  Alcotest.(check int) "exclude project 1" 2 (List.length (Report.all_krs t1));
  let t2 = filter t ~exclude_projects:[ p1; p2 ] in
  Alcotest.(check int)
    "exclude projects 1,2" 0
    (List.length (Report.all_krs t2))

let test_include_objectives () =
  let t = report () in
  let t1 = filter t ~include_objectives:[ o1 ] in
  Alcotest.(check int) "include objective 1" 1 (List.length (Report.all_krs t1));
  let t2 = filter t ~include_objectives:[ o1; o2 ] in
  Alcotest.(check int)
    "include objectives 1,2" 3
    (List.length (Report.all_krs t2))

let test_exclude_objectives () =
  let t = report () in
  let t1 = filter t ~exclude_objectives:[ o1 ] in
  Alcotest.(check int) "exclude objective 1" 2 (List.length (Report.all_krs t1));
  let t1 = filter t ~include_objectives:[ o2 ] ~exclude_objectives:[ o1 ] in
  Alcotest.(check int) "exclude objective 1" 2 (List.length (Report.all_krs t1));
  let t2 = filter t ~exclude_projects:[ p1; p2 ] in
  Alcotest.(check int)
    "exclude objectives 1,2" 0
    (List.length (Report.all_krs t2))

let test_include_krs () =
  let t = report () in
  let t1 = filter t ~include_krs:[ ID id2 ] in
  Alcotest.(check int) "include KRs 2" 1 (List.length (Report.all_krs t1));
  let t1' = filter t ~include_krs:[ ID (String.uppercase_ascii id2) ] in
  Alcotest.(check int) "include KRs 2" 1 (List.length (Report.all_krs t1'));
  let t2 = filter t ~include_krs:[ ID id2; ID id3 ] in
  Alcotest.(check int) "include KRs 2,3" 2 (List.length (Report.all_krs t2));
  let t3 = filter t ~include_krs:[ New_KR ] in
  Alcotest.(check int) "include New KRs" 1 (List.length (Report.all_krs t3))

let test_exclude_krs () =
  let t = report () in
  let t1 = filter t ~exclude_krs:[ ID id2 ] in
  Alcotest.(check int) "exclude KRs 2" 2 (List.length (Report.all_krs t1));
  let t1 = filter t ~include_krs:[ New_KR; ID id3 ] ~exclude_krs:[ ID id2 ] in
  Alcotest.(check int) "exclude KRs 2" 2 (List.length (Report.all_krs t1));
  let t2 = filter t ~exclude_krs:[ ID id2; ID id3 ] in
  Alcotest.(check int) "exclude KRs 2,3" 1 (List.length (Report.all_krs t2))

let test_include_engineers () =
  let t = report () in
  let t1 = filter t ~include_engineers:[ e1 ] in
  Alcotest.(check int) "include foo" 2 (List.length (Report.all_krs t1));
  let t2 = filter t ~include_engineers:[ e1; e2 ] in
  Alcotest.(check int) "include foo,bar" 3 (List.length (Report.all_krs t2))

let get_kr t =
  match Report.all_krs t with
  | [] -> Alcotest.fail "invalide filter: empty result"
  | [ x ] -> x
  | _ -> Alcotest.fail "invalid filter: too many results"

let test_exclude_engineers () =
  let t = report () in
  let t1 = filter t ~exclude_engineers:[ e1 ] in
  Alcotest.(check int) "exclude foo" 1 (List.length (Report.all_krs t1));
  let t2 = filter t ~exclude_engineers:[ e1; e2 ] in
  Alcotest.(check int) "exclude foo,bar" 0 (List.length (Report.all_krs t2));

  (* check that counter do not change if the KR filter return total KRs. *)
  let t1 = filter t ~include_krs:[ ID id2 ] ~include_engineers:[ e1 ] in
  let kr = get_kr t1 in
  Alcotest.(check int) "check counter" kr2.KR.counter kr.KR.counter;

  let t2 = filter t ~include_krs:[ ID id3 ] ~include_engineers:[ e2 ] in
  let kr = get_kr t2 in
  Alcotest.(check (list (list (pair string Alcotest_ext.time))))
    "check time entries"
    [ [ (e2, T.days 10.) ] ]
    kr.KR.time_entries

let tests =
  [
    ("include projects", `Quick, test_include_projects);
    ("exclude projects", `Quick, test_exclude_projects);
    ("include objectives", `Quick, test_include_objectives);
    ("exclude objectives", `Quick, test_exclude_objectives);
    ("include KRs", `Quick, test_include_krs);
    ("exclude KRs", `Quick, test_exclude_krs);
    ("include engineers", `Quick, test_include_engineers);
    ("exclude engineers", `Quick, test_exclude_engineers);
  ]
