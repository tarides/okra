module Unit : sig
  type t = Day

  val of_string : string -> t option
end

type t = { data : float; unit : Unit.t }

val nil : t
val days : float -> t
val equal : t -> t -> bool
val add : t -> t -> t
val ( +. ) : t -> t -> t
val pp : t Fmt.t
