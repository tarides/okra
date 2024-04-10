module Unit = struct
  type t = Day | Hour

  let of_string = function "day" -> Some Day | "hour" -> Some Hour | _ -> None

  let equal x y =
    match (x, y) with
    | Day, Day | Hour, Hour -> true
    | Day, Hour | Hour, Day -> false

  let pp fs = function Day -> Fmt.pf fs "day" | Hour -> Fmt.pf fs "hour"
end

type t = { data : float; unit : Unit.t }

let equal x y =
  if Unit.equal x.unit y.unit then Float.equal x.data y.data
  else x.data = 0. && y.data = 0.

let nil = { unit = Day; data = 0. }
let days data = { unit = Day; data }
let hours data = { unit = Hour; data }
let day_to_hour x = x *. 8.

let add x y =
  let warning = "converting days metric into hours (considering 8h/day)" in
  match (x.unit, y.unit) with
  | Day, Day | Hour, Hour -> { unit = x.unit; data = x.data +. y.data }
  | Day, Hour ->
      Logs.warn (fun m -> m "%s" warning);
      { unit = Hour; data = day_to_hour x.data +. y.data }
  | Hour, Day ->
      Logs.warn (fun m -> m "%s" warning);
      { unit = Hour; data = x.data +. day_to_hour y.data }

let ( +. ) = add

let pp fs { unit; data } =
  let pp_float fs f =
    if classify_float (fst (modf f)) = FP_zero then Fmt.pf fs "%.0f" f
    else Fmt.pf fs "%.1f" f
  in
  if data = 1. then Fmt.pf fs "1 %a" Unit.pp unit
  else Fmt.pf fs "%a %as" pp_float data Unit.pp unit
