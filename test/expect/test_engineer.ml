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

let activity =
  let open Get_activity.Contributions in
  let projects =
    [ Activity.{ title = "Make okra great (OKRA1)"; items = [] } ]
  in
  let items : item list =
    [
      {
        repo = "bactrian/okra";
        kind = `PR;
        date = "";
        title = "Fix bug in Okra";
        body = "Fixes a bug in Okra";
        url = "https://github.com/bactrian/okra/pull/42";
      };
      {
        repo = "bactrian/okra";
        kind = `PR;
        date = "";
        title = "Fix another bug in Okra";
        body = "Fixes another bug in Okra";
        url = "https://github.com/bactrian/okra/pull/43";
      };
      {
        repo = "bactrian/okra";
        kind = `Issue;
        date = "";
        title = "There's a bug in Okra";
        body = "A bad bug in Okra";
        url = "https://github.com/bactrian/okra/issue/26";
      };
      {
        repo = "bactrian/okra";
        kind = `Review "APPROVED";
        date = "";
        title = "Fix another bug in Okra";
        body = "Fixes another bug in Okra";
        url =
          "https://github.com/bactrian/okra/pull/43#pullrequestreview-123456789";
      };
      {
        repo = "bactrian/okra-web";
        kind = `New_repo;
        date = "";
        title = "Web";
        body = "Web";
        url = "https://github.com/bactrian/okra-web";
      };
    ]
  in
  let (activity : item list Repo_map.t) =
    List.fold_left
      (fun map item -> Repo_map.add "bactrian/okra" item map)
      Repo_map.empty [ items ]
  in
  let activities = { username = "bactrian"; activity } in
  Activity.make ~projects activities

let () = Activity.pp ~print_projects:false () Fmt.stdout activity
