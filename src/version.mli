module Lang : sig
  type t = { major : int; minor : int }

  val pp : Format.formatter -> t -> unit
  val to_string : t -> string
  val of_string : string -> (t, [ `Msg of string ]) result
end

module Lib : sig
  type t = Release of { major : int; minor : int; patch : int } | Dev

  val pp : Format.formatter -> t -> unit
  val to_string : t -> string
  val of_string : string -> (t, [ `Msg of string ]) result
  val can_read : lang:Lang.t -> t -> bool
end

val current : Lib.t
