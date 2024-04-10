module Unit = struct
  type t = Day

  let of_string = function "day" -> Some Day | _ -> None
  let equal x y = match (x, y) with Day, Day -> true
  let pp fs = function Day -> Fmt.pf fs "day"
end

type t = { data : float; unit : Unit.t }

let equal x y =
  if Unit.equal x.unit y.unit then Float.equal x.data y.data
  else x.data = 0. && y.data = 0.

let nil = { unit = Day; data = 0. }
let days data = { unit = Day; data }

let add x y =
  match (x.unit, y.unit) with
  | Day, Day -> { unit = x.unit; data = x.data +. y.data }

let ( +. ) = add

let pp fs { unit; data } =
  let pp_float fs f =
    if classify_float (fst (modf f)) = FP_zero then Fmt.pf fs "%.0f" f
    else Fmt.pf fs "%.1f" f
  in
  if data = 1. then Fmt.pf fs "1 %a" Unit.pp unit
  else Fmt.pf fs "%a %as" pp_float data Unit.pp unit
