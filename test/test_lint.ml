(*
 * Copyright (c) 2021 Magnus Skjegstad <magnus@skjegstad.com>
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

let lint_file ?(include_sections = []) ?(ignore_sections = []) f =
  let ic = open_in f in
  let res = Okra.Lint.lint ~include_sections ~ignore_sections ic in
  close_in ic;
  res

let test_no_work_found f () =
  match lint_file f with
  | Okra.Lint.No_work_found _ -> Alcotest.(check pass) "" 0 0
  | x ->
      Alcotest.fail
        (Fmt.str "Invalid result in file %s:\n%s" f
           (Okra.Lint.string_of_result x))

let test_invalid_time f () =
  match lint_file f with
  | Okra.Lint.Invalid_time _ -> Alcotest.(check pass) "" 0 0
  | x ->
      Alcotest.fail
        (Fmt.str "Invalid result in file %s:\n%s" f
           (Okra.Lint.string_of_result x))

let test_valid_time f () =
  match lint_file f with
  | Okra.Lint.No_error -> Alcotest.(check pass) "" 0 0
  | x ->
      Alcotest.fail
        (Fmt.str "Invalid result in file %s:\n%s" f
           (Okra.Lint.string_of_result x))

let test_no_time_found f () =
  match lint_file f with
  | Okra.Lint.No_time_found _ -> Alcotest.(check pass) "" 0 0
  | x ->
      Alcotest.fail
        (Fmt.str "Invalid result in file %s:\n%s" f
           (Okra.Lint.string_of_result x))

let test_multiple_time_entries f () =
  match lint_file f with
  | Okra.Lint.Multiple_time_entries _ -> Alcotest.(check pass) "" 0 0
  | x ->
      Alcotest.fail
        (Fmt.str "Invalid result in file %s:\n%s" f
           (Okra.Lint.string_of_result x))

let test_format_errors f n () =
  match lint_file f with
  | Okra.Lint.Format_error l ->
      Alcotest.(check int)
        (Fmt.str "Incorrect number of formatting errors in file %s: %s\n" f
           (Okra.Lint.string_of_result (Okra.Lint.Format_error l)))
        (List.length l) n
  | x ->
      Alcotest.fail
        (Fmt.str "Invalid result in file %s:\n%s" f
           (Okra.Lint.string_of_result x))

let test_valid_eng_report f () =
  match lint_file ~include_sections:[ "Last week" ] f with
  | Okra.Lint.No_error -> Alcotest.(check pass) "" 0 0
  | x ->
      Alcotest.fail
        (Fmt.str "Invalid result in file %s:\n%s" f
           (Okra.Lint.string_of_result x))

let test_invalid_eng_report f () =
  (* Test that errors in include section are detected even if the rest is ignored *)
  match lint_file ~include_sections:[ "Last week" ] f with
  | Okra.Lint.No_error ->
      Alcotest.fail
        (Fmt.str "No error when linting invalid engineering report %s" f)
  | _ -> Alcotest.(check pass) "" 0 0

let test_valid_team_report f () =
  match lint_file ~ignore_sections:[ "OKR Updates" ] f with
  | Okra.Lint.No_error -> Alcotest.(check pass) "" 0 0
  | x ->
      Alcotest.fail
        (Fmt.str "Invalid result in file %s:\n%s" f
           (Okra.Lint.string_of_result x))

let test_invalid_team_report f () =
  (* Test that it doesn't ignore errors outside the ignored section *)
  match lint_file ~ignore_sections:[ "OKR updates" ] f with
  | Okra.Lint.No_error ->
      Alcotest.fail (Fmt.str "No error when linting invalid team report %s" f)
  | _ -> Alcotest.(check pass) "" 0 0

let test_no_kr_id_found f () =
  match lint_file f with
  | Okra.Lint.No_KR_ID_found _ -> Alcotest.(check pass) "" 0 0
  | x ->
      Alcotest.fail
        (Fmt.str "Invalid result in file %s:\n%s" f
           (Okra.Lint.string_of_result x))

let test_no_title_found f () =
  match lint_file f with
  | Okra.Lint.No_title_found _ -> Alcotest.(check pass) "" 0 0
  | x ->
      Alcotest.fail
        (Fmt.str "Invalid result in file %s:\n%s" f
           (Okra.Lint.string_of_result x))

let tests =
  [
    ("Test_valid_eng_report", `Quick, test_valid_eng_report "./lint/eng1.acc");
    ( "Test_invalid_eng_report",
      `Quick,
      test_invalid_eng_report "./lint/eng1.rej" );
    ("Test_valid_team_report", `Quick, test_valid_team_report "./lint/team1.acc");
    ("Test_valid_team_report", `Quick, test_valid_team_report "./lint/team2.acc");
    ("Test_valid_team_report", `Quick, test_valid_team_report "./lint/team3.acc");
    ( "Test_invalid_team_report",
      `Quick,
      test_invalid_team_report "./lint/team1.rej" );
    ("No_KR_ID_found", `Quick, test_no_kr_id_found "./lint/no-kr1.rej");
    ("No_title_found", `Quick, test_no_title_found "./lint/no-title1.rej");
    ("No_work_found", `Quick, test_no_work_found "./lint/no-work1.rej");
    ("No_time_found", `Quick, test_no_time_found "./lint/no-time1.rej");
    ( "Multiple_time_entries",
      `Quick,
      test_multiple_time_entries "./lint/multitime1.rej" );
    ("Format_errors", `Quick, test_format_errors "./lint/format1.rej" 1);
    ("Format_errors", `Quick, test_format_errors "./lint/format2.rej" 1);
    ("Format_errors", `Quick, test_format_errors "./lint/format3.rej" 1);
    ("Invalid_time", `Quick, test_invalid_time "./lint/invalid-time1.rej");
    ("Invalid_time", `Quick, test_invalid_time "./lint/invalid-time2.rej");
    ("Invalid_time", `Quick, test_invalid_time "./lint/invalid-time3.rej");
    ("Invalid_time", `Quick, test_invalid_time "./lint/invalid-time4.rej");
    ("Invalid_time", `Quick, test_invalid_time "./lint/invalid-time5.rej");
    ("Invalid_time", `Quick, test_invalid_time "./lint/invalid-time6.rej");
    ("Valid_time", `Quick, test_valid_time "./lint/valid-time1.acc");
  ]
