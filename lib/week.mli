type t = { year : int; week : int }

val compare : t -> t -> int
val pp : t Fmt.t
val of_filename : filename:string -> t option
