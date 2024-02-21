let int_of_string_result s =
  match int_of_string s with i -> Ok i | exception Failure e -> Error (`Msg e)

module Result = struct
  include Result

  module Let_syntax = struct
    let ( let+ ) x f = Result.map f x
    let ( let* ) = Result.bind
  end
end

module Lang = struct
  type t = { major : int; minor : int }

  let pp fs v = Format.fprintf fs "%i.%i" v.major v.minor
  let to_string v = Format.asprintf "%a" pp v

  let of_string s =
    let open Result.Let_syntax in
    match String.split_on_char '.' s with
    | [ a; b ] ->
        let* major = int_of_string_result a in
        let+ minor = int_of_string_result b in
        { major; minor }
    | _ -> Error (`Msg "Lang.of_string: invalid string format")
end

module Lib = struct
  type t = Release of { major : int; minor : int; patch : int } | Dev

  let pp fs = function
    | Release v -> Format.fprintf fs "%i.%i.%i" v.major v.minor v.patch
    | Dev -> Format.fprintf fs "dev"

  let to_string v = Format.asprintf "%a" pp v

  let of_string s =
    let open Result.Let_syntax in
    match s with
    | "dev" -> Ok Dev
    | _ -> (
        match String.split_on_char '.' s with
        | [ a; b; c ] ->
            let* major = int_of_string_result a in
            let* minor = int_of_string_result b in
            let+ patch = int_of_string_result c in
            Release { major; minor; patch }
        | _ -> Error (`Msg "Lib.of_string: invalid string format"))

  let can_read ~lang = function
    | Release { major; minor; patch = _ } ->
        Int.compare major lang.Lang.major > 0
        || Int.compare major lang.major = 0
           && Int.compare minor lang.minor >= 0
    | Dev -> true (* more advanced than any release *)
end

let current =
  let open Build_info.V1 in
  match version () with
  | Some v -> (
      let s = Version.to_string v in
      match Lib.of_string s with Ok v -> v | Error _ -> Dev)
  | None -> Dev
