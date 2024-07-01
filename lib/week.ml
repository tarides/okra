type t = { year : int; week : int }

let pp ppf x = Fmt.pf ppf "%i %i" x.year x.week

let compare x y =
  match Int.compare x.year y.year with 0 -> compare x.week y.week | x -> x

let of_filename ~filename =
  let segs = Fpath.segs (Fpath.v filename) in
  let rec strip_prefix = function
    | [] -> []
    | "weekly" :: _ as x -> x
    | _ :: x -> strip_prefix x
  in
  let segs = strip_prefix segs in
  match segs with
  | [ "weekly"; year; week; _file ] ->
      let ( let* ) = Option.bind in
      let* year = int_of_string_opt year in
      let* week = int_of_string_opt week in
      if 1 <= week && week <= 53 then Some { year; week } else None
  | _ -> None
