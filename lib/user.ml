type t = string

let pp ~with_link ppf u =
  if with_link then Fmt.pf ppf "[@%s](https://github.com/%s)" u u
  else Fmt.pf ppf "@%s" u
