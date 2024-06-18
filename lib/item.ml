(*
 * Copyright (c) 2021 Magnus Skjegstad
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

type t = Omd.attributes Omd.block
type inline = Omd.attributes Omd.inline

(* Dump contents *)

let dump_list_type ppf = function
  | Omd.Ordered (d, c) -> Fmt.pf ppf "Ordered (%d, %c)" d c
  | Bullet c -> Fmt.pf ppf "Bullet %c" c

let rec dump_inline ppf = function
  | Omd.Concat (_, c) -> Fmt.pf ppf "Concat %a" (Fmt.Dump.list dump_inline) c
  | Text (_, s) -> Fmt.pf ppf "Text %S" s
  | Emph (_, e) -> Fmt.pf ppf "Emph (%a)" dump_inline e
  | Strong (_, e) -> Fmt.pf ppf "Strong (%a)" dump_inline e
  | Code (_, s) -> Fmt.pf ppf "Code %S" s
  | Hard_break _ -> Fmt.pf ppf "Hard_break"
  | Soft_break _ -> Fmt.pf ppf "Soft_break"
  | Link (_, l) -> Fmt.pf ppf "Link %a" dump_link l
  | Image (_, l) -> Fmt.pf ppf "Image %a" dump_link l
  | Html (_, s) -> Fmt.pf ppf "Html %S" s

and dump_link ppf t =
  let open Fmt.Dump in
  record
    [
      field "label" (fun x -> x.Omd.label) dump_inline;
      field "destination" (fun x -> x.Omd.destination) string;
      field "title" (fun x -> x.Omd.title) (option string);
    ]
    ppf t

and dump_def_elt ppf t =
  let open Fmt.Dump in
  record
    [
      field "term" (fun x -> x.Omd.term) dump_inline;
      field "defs" (fun x -> x.Omd.defs) Fmt.Dump.(list dump_inline);
    ]
    ppf t

let rec dump ppf = function
  | Omd.Paragraph (_, t) -> Fmt.pf ppf "Paragraph (%a)" dump_inline t
  | List (_, x, _, y) ->
      Fmt.pf ppf "List (%a, %a)" dump_list_type x Fmt.Dump.(list (list dump)) y
  | Blockquote (_, l) -> Fmt.pf ppf "Blockquote %a" Fmt.(Dump.list dump) l
  | Code_block (_, x, y) -> Fmt.pf ppf "Code_block (%S, %S)" x y
  | Heading (_, n, x) -> Fmt.pf ppf "Heading (%d, %a)" n dump_inline x
  | Thematic_break _ -> Fmt.pf ppf "Thematic_break"
  | Html_block (_, s) -> Fmt.pf ppf "Html_block %S" s
  | Definition_list (_, l) ->
      Fmt.pf ppf "Definition_list (%a)" (Fmt.Dump.list dump_def_elt) l
  | Table _ -> Fmt.pf ppf "Table _"

(* Pretty-print contents *)

open Fmt

let newline = Format.pp_force_newline

let rec pp_inline ppf = function
  | Omd.Concat (_, c) -> list ~sep:nop pp_inline ppf c
  | Text (_, s) -> string ppf s
  | Emph (_, e) ->
      string ppf "_";
      pp_inline ppf e;
      string ppf "_"
  | Strong (_, e) ->
      string ppf "__";
      pp_inline ppf e;
      string ppf "__"
  | Code (_, s) ->
      string ppf "`";
      string ppf s;
      string ppf "`"
  | Hard_break _ ->
      newline ppf ();
      newline ppf ()
  | Soft_break _ -> newline ppf ()
  | Link (_, l) ->
      string ppf "[";
      pp_inline ppf l.label;
      string ppf "](";
      string ppf l.destination;
      string ppf ")"
  | Image (_, l) ->
      string ppf "![";
      pp_inline ppf l.label;
      string ppf "](";
      string ppf l.destination;
      string ppf ")"
  | Html (_, s) -> string ppf s

let rec pp ppf = function
  | Omd.Paragraph (_, t) -> pp_inline ppf t
  | Omd.List (_, Ordered (i, c), _, y) ->
      list ~sep:nop
        (fun ppf e ->
          int ppf i;
          char ppf c;
          char ppf ' ';
          box (list ~sep:newline pp) ppf e)
        ppf y
  | Omd.List (_, Bullet c, _, y) ->
      list ~sep:newline
        (fun ppf e ->
          char ppf c;
          char ppf ' ';
          box (list ~sep:newline pp) ppf e)
        ppf y
  | Blockquote (_, l) ->
      string ppf "> ";
      List.iter (pp ppf) l
  | Code_block (_, lang, code) ->
      string ppf "```";
      string ppf lang;
      newline ppf ();
      lines ppf code;
      string ppf "```"
  | Heading (_, lvl, x) ->
      string ppf (String.make lvl '#');
      char ppf ' ';
      pp_inline ppf x
  | Thematic_break _ -> Fmt.pf ppf "---"
  | Html_block (_, s) -> Fmt.pf ppf "%s" s
  | Definition_list (_, l) ->
      let sep ppf () =
        newline ppf ();
        Fmt.string ppf ": "
      in
      list ~sep:newline
        (fun ppf { Omd.term; defs } -> list ~sep pp_inline ppf (term :: defs))
        ppf l
  | Table (_, headers, rows) ->
      let bar ppf () = Fmt.string ppf " | " in
      pf ppf "| %a |"
        (list ~sep:bar (fun ppf (e, _align) -> pp_inline ppf e))
        headers;
      newline ppf ();
      pf ppf "| %a |" (list ~sep:bar (fun ppf _ -> string ppf "---")) headers;
      newline ppf ();
      list ~sep:newline
        (fun ppf row ->
          pf ppf "| %a |" (list ~sep:bar (fun ppf e -> pp_inline ppf e)) row)
        ppf rows
