(** {1 Filtering} *)

type t

val empty : t
val apply : t -> Report.t -> Report.t

val kr_of_string : string -> KR.Work.Id.t
(** [kr_of_string s] is [`New_KR] iff [s="New KR"], [`No_kr] iff [s="No KR"],
    and [`ID s] otherwise. *)

val string_of_kr : KR.Work.Id.t -> string

val union : t -> t -> t
(** Combine two filters into a new filter *)

val v :
  ?include_projects:string list ->
  ?exclude_projects:string list ->
  ?include_objectives:string list ->
  ?exclude_objectives:string list ->
  ?include_krs:KR.Work.Id.t list ->
  ?exclude_krs:KR.Work.Id.t list ->
  ?include_engineers:string list ->
  ?exclude_engineers:string list ->
  unit ->
  t
(** Build a filter.

    Keep the KR [k] in the report iff the conjonction of the following is true:

    - [include_project] is not empty AND [k.project] is in [include_projects] OR
      [exclude_project] is not empty AND [k.project] is not in
      [exclude_project];
    - [include_objective] is not empty AND [k.objective] is in
      [include_objectives] OR [exclude_objectives] is not empty AND
      [k.objective] is not in [exclude_projects];
    - [include_krs] is not empty AND [k.krs] is [Some id] AND [id] is in
      [include_krs] OR [exclude_krs] is not empty AND [k.krs] is [Some id] AND
      [id] is not in [exclude_projects];
    - [include_engineers] is not empty AND the intersection of
      [k.time_per_engineer] and [include_engineers] is not empty OR
      [exclude_krs] is not empty AND [k.time_per_engineer] and
      [exclude_engineers] is empty. *)
