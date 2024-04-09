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

let repo_report =
  let open Repo_report in
  let map : data Project_map.t = Project_map.empty in
  let data : data =
    Repo_report.
      {
        org = "mirage";
        repo = "irmin";
        description =
          Some
            "Irmin is a distributed database that follows the same design \
             principles as Git";
        issues =
          [
            Issue.
              {
                author = Some "Dromedary";
                title = "Small bug";
                cursor = "wkjgkdjlsghwkl";
                url = "https://github.com/mirage/irmin/issues/2200";
                body = "A small bug";
                closed = false;
                closed_at = None;
                created_at = "2021-01-27T00:00:00Z";
              };
          ];
        prs =
          PR.
            [
              {
                author = Some "Bactrian";
                cursor = "ABCDEFGHIJKLM";
                url = "https://github.com/mirage/irmin/issues/2210";
                title = "Small fix";
                body = "Fixes a small thing";
                closed = false;
                closed_at = None;
                created_at = "2021-02-01T00:00:00Z";
                is_draft = false;
                merged_at = None;
                merged_by = None;
                reviewers = [ "Dromedary" ];
              };
              {
                author = Some "Bactrian";
                cursor = "ZYXW";
                url = "https://github.com/mirage/irmin/issues/2220";
                title = "Smaller fix";
                body = "Fixes a really small thing";
                closed = false;
                closed_at = None;
                created_at = "2021-02-01T00:00:01Z";
                is_draft = false;
                merged_at = Some "2021-02-01T00:00:02Z";
                merged_by = Some "Dromedary";
                reviewers = [ "Dromedary" ];
              };
            ];
      }
  in
  Project_map.add "mirage/irmin" data map

let () =
  Repo_report.pp ~with_names:true ~with_times:true ~with_descriptions:true
    Fmt.stdout repo_report
