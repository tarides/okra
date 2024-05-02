type t = { year : int; quarter : [ `Q1 | `Q2 | `Q3 | `Q4 ] }

let pp ppf x =
  let pp_quarter ppf = function
    | `Q1 -> Fmt.pf ppf "Q1"
    | `Q2 -> Fmt.pf ppf "Q2"
    | `Q3 -> Fmt.pf ppf "Q3"
    | `Q4 -> Fmt.pf ppf "Q4"
  in
  Fmt.pf ppf "%i %a" x.year pp_quarter x.quarter

let compare x y =
  match Int.compare x.year y.year with
  | 0 -> compare x.quarter y.quarter
  | x -> x

let of_string s =
  let err_msg = Error (`Msg (Fmt.str "invalid quarter %S" s)) in
  match String.split_on_char ' ' s with
  | [] -> Ok None
  | [ "" ] -> Ok None
  | [ "Rolling" ] -> Ok None
  | quarter :: year :: _ -> (
      match int_of_string_opt year with
      | Some year -> (
          match quarter with
          | "Q1" -> Ok (Some { year; quarter = `Q1 })
          | "Q2" -> Ok (Some { year; quarter = `Q2 })
          | "Q3" -> Ok (Some { year; quarter = `Q3 })
          | "Q4" -> Ok (Some { year; quarter = `Q4 })
          | _ -> err_msg)
      | None -> err_msg)
  | _ -> err_msg

let of_filename ~filename =
  let segs = Fpath.segs (Fpath.v filename) in
  let rec strip_prefix = function
    | [] -> []
    | "weekly" :: _ as x -> x
    | _ :: x -> strip_prefix x
  in
  let segs = strip_prefix segs in
  match segs with
  | [ "weekly"; year; week; _file ] -> (
      match int_of_string_opt year with
      | Some year -> (
          (* each quarter is 13 weeks, either 4-4-5, 4-5-4, or 5-4-4 *)
          match int_of_string_opt week with
          | Some x when 1 <= x && x <= 13 -> Some { year; quarter = `Q1 }
          | Some x when 14 <= x && x <= 26 -> Some { year; quarter = `Q2 }
          | Some x when 27 <= x && x <= 39 -> Some { year; quarter = `Q3 }
          | Some x when 40 <= x && x <= 53 -> Some { year; quarter = `Q4 }
          | _ -> None)
      | None -> None)
  | _ -> None

let check q kr_q =
  match (q, kr_q) with
  | None, _ | _, None -> true
  | Some q, Some kr_q -> compare q kr_q = 0
