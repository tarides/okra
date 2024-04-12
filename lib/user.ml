type t = string

let md_url_regexp ~extract =
  let open Re in
  let maybe_group = if extract then group ?name:None else fun x -> x in
  let username = rep1 (alt [ wordc; char '-' ]) in
  let txt = seq [ char '@'; maybe_group username ] in
  let url = seq [ str "https://github.com/"; username ] in
  seq [ char '['; txt; char ']'; char '('; url; char ')' ]

let regexp =
  let open Re in
  let username = rep1 (alt [ wordc; char '-' ]) in
  let with_url = md_url_regexp ~extract:false in
  let without_url = seq [ char '@'; username ] in
  alt [ with_url; without_url ]

let of_string s =
  let default = String.sub s 1 (String.length s - 1) in
  match Re.exec_opt (Re.compile (md_url_regexp ~extract:true)) s with
  | Some grp -> Option.value (Re.Group.get_opt grp 1) ~default
  | None -> default

let pp ~with_link ppf u =
  if with_link then Fmt.pf ppf "[@%s](https://github.com/%s)" u u
  else Fmt.pf ppf "%s" u
