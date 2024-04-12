type t = string

val of_string : string -> t
val regexp : Re.t
val pp : with_link:bool -> t Fmt.t
