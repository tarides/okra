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

open Okra

let result_or_int ~ok = function
  | Ok _ -> Int.to_string ok
  | Error (`Msg x) -> x

let result_or_range ~ok:(x, y) = function
  | Ok _ -> Format.sprintf "(%i,%i)" x y
  | Error (`Msg x) -> x

let check_week week year ~expected () =
  let test_name = Format.sprintf "check_week %i" week in
  let actual = Calendar.of_week ~year week |> result_or_int ~ok:week in
  Alcotest.(check string) test_name expected actual

let check_week_range (x, y) year ~expected () =
  let test_name = Format.sprintf "check_week_range (%i,%i)" x y in
  let actual =
    Calendar.of_week_range ~year (x, y) |> result_or_range ~ok:(x, y)
  in
  Alcotest.(check string) test_name expected actual

let check_month month year ~expected () =
  let test_name = Format.sprintf "check_month %i" month in
  let actual = Calendar.of_month ~year month |> result_or_int ~ok:month in
  Alcotest.(check string) test_name expected actual

let check_result = function Ok x -> x | Error (`Msg e) -> Alcotest.fail e

let test_week monday sunday week year () =
  let week = Calendar.of_week ~year week |> check_result in
  let gen_monday, gen_sunday = Calendar.to_iso8601 week in
  Alcotest.(check string) "same monday" monday gen_monday;
  Alcotest.(check string) "same sunday" sunday gen_sunday

let test_week_range monday sunday week year () =
  let week = Calendar.of_week_range ~year week |> check_result in
  let gen_monday, gen_sunday = Calendar.to_iso8601 week in
  Alcotest.(check string) "same monday" monday gen_monday;
  Alcotest.(check string) "same sunday" sunday gen_sunday

let test_month first last month year () =
  let month = Calendar.of_month ~year month |> check_result in
  let gen_first, gen_last = Calendar.to_iso8601 month in
  Alcotest.(check string) "same first" first gen_first;
  Alcotest.(check string) "same last" last gen_last

let tests =
  [
    ("week_0_2019", `Quick, check_week 0 2019 ~expected:"invalid week: 0");
    ("week_52_2019", `Quick, check_week 52 2019 ~expected:"52");
    ("week_53_2019", `Quick, check_week 53 2019 ~expected:"invalid week: 53");
    ("week_0_2020", `Quick, check_week 0 2020 ~expected:"invalid week: 0");
    ("week_52_2020", `Quick, check_week 52 2020 ~expected:"52");
    ("week_53_20120", `Quick, check_week 53 2020 ~expected:"53");
    ("week_0_2023", `Quick, check_week 0 2023 ~expected:"invalid week: 0");
    ("week_52_2023", `Quick, check_week 52 2023 ~expected:"52");
    ("week_53_2023", `Quick, check_week 53 2023 ~expected:"invalid week: 53");
    ( "week_1_2020",
      `Quick,
      test_week "2019-12-30T00:00:00Z" "2020-01-05T23:59:59Z" 1 2020 );
    ( "week_1_2021",
      `Quick,
      test_week "2021-01-04T00:00:00Z" "2021-01-10T23:59:59Z" 1 2021 );
    ( "week_1_2022",
      `Quick,
      test_week "2022-01-03T00:00:00Z" "2022-01-09T23:59:59Z" 1 2022 );
    ( "weeks_1_4_2022",
      `Quick,
      test_week_range "2022-01-03T00:00:00Z" "2022-01-30T23:59:59Z" (1, 4) 2022
    );
    ( "weeks_35_38_2021",
      `Quick,
      test_week_range "2021-08-30T00:00:00Z" "2021-09-26T23:59:59Z" (35, 38)
        2021 );
    ( "week_0_1_2023",
      `Quick,
      check_week_range (0, 1) 2023 ~expected:"invalid week: 0" );
    ( "week_51_50_2023",
      `Quick,
      check_week_range (51, 50) 2023 ~expected:"invalid week range: 51-50" );
    ( "week_35_2021",
      `Quick,
      test_week "2021-08-30T00:00:00Z" "2021-09-05T23:59:59Z" 35 2021 );
    ( "month_1_2021",
      `Quick,
      test_month "2021-01-01T00:00:00Z" "2021-01-31T23:59:59Z" 1 2021 );
    ("month_0_2020", `Quick, check_month 0 2020 ~expected:"invalid month: 0");
    ("month_1_2020", `Quick, check_month 1 2020 ~expected:"1");
    ("month_12_2020", `Quick, check_month 12 2020 ~expected:"12");
    ("month_13_2020", `Quick, check_month 13 2020 ~expected:"invalid month: 13");
    ( "month_12_1998",
      `Quick,
      test_month "1998-12-01T00:00:00Z" "1998-12-31T23:59:59Z" 12 1998 );
  ]
