type t

val compare : t -> t -> int
val pp : t Fmt.t
val of_string : string -> (t option, [ `Msg of string ]) result
val of_filename : filename:string -> t option
