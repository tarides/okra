module Kr = struct
  type schedule = Quarterly of [ `Q1 | `Q2 | `Q3 | `Q4 ] * int | Rolling
  [@@deriving yojson]

  type status =
    | Scheduled of schedule
    | Unscheduled
    | No_status
    | Active
    | Unfunded
    | Blocked
  [@@deriving yojson]

  let quarter_of_string = function
    | "q1" -> `Q1
    | "q2" -> `Q2
    | "q3" -> `Q3
    | "q4" -> `Q4
    | _ -> failwith "Failed to parser quarter"

  let quarter_to_string = function
    | `Q1 -> "Q1"
    | `Q2 -> "Q2"
    | `Q3 -> "Q3"
    | `Q4 -> "Q4"

  let schedule_to_string = function
    | Quarterly (q, i) ->
        "(" ^ quarter_to_string q ^ " " ^ string_of_int i ^ ")"
    | Rolling -> "(rolling)"

  let status_of_string s =
    match String.lowercase_ascii s with
    | "unscheduled" -> Unscheduled
    | "no status" -> No_status
    | "active" -> Active
    | "blocked" -> Blocked
    | "unfunded" -> Unfunded
    | "scheduled (rolling)" -> Scheduled Rolling
    | s -> (
        match String.split_on_char ' ' s with
        | [ "scheduled"; quarter; year ] ->
            let quarter =
              quarter_of_string String.(sub quarter 1 (length quarter - 1))
            in
            let year = int_of_string String.(sub year 0 (length year - 1)) in
            Scheduled (Quarterly (quarter, year))
        | _ -> failwith ("Failed to parse status: " ^ s))

  let status_to_string = function
    | Unscheduled -> "Unscheduled"
    | No_status -> "No Status"
    | Active -> "Active"
    | Blocked -> "Blocked"
    | Unfunded -> "Unfunded"
    | Scheduled s -> "Scheduled " ^ schedule_to_string s

  type t = {
    title : string;
    owner : string option;
    ident : string;
    status : status;
  }
  [@@deriving yojson]

  let v ~status s =
    let get_owner_or_ident s =
      match String.split_on_char ')' s with
      | "" :: _ -> None
      | o :: _ -> Some o
      | _ -> None
    in
    let rec aux title = function
      | [ owner; ident ] ->
          {
            title = String.trim (List.rev title |> String.concat "(");
            owner = get_owner_or_ident owner;
            ident = get_owner_or_ident ident |> Option.get;
            status;
          }
      | x :: xs -> aux (x :: title) xs
      | _ -> raise (Failure ("Failed to parse KR: " ^ s))
    in
    aux [] (String.split_on_char '(' s)
end

module Objective = struct
  type t = { title : string; krs : Kr.t list } [@@deriving yojson]

  let of_block b =
    let of_paragraph ~status = function
      | [ Omd.Paragraph ([], Omd.Text ([], kr)) ] -> Kr.v ~status kr
      | [ Omd.Paragraph ([], Omd.Concat ([], kr)) ] ->
          Kr.v ~status
            (Aggregate.inline (Omd.Concat ([], kr)) |> String.concat "")
      | _ -> failwith ("Expected a paragraph and text: " ^ Omd.to_sexp b)
    in
    let of_list ~status = function
      | Omd.List ([], _, _, lst) -> List.map (of_paragraph ~status) lst
      | _ -> failwith "Expected a list of paragraphs"
    in
    let rec from_headings acc = function
      | Omd.Heading ([], 3, Omd.Text ([], t)) :: lst :: rest ->
          from_headings (of_list ~status:(Kr.status_of_string t) lst @ acc) rest
      | _ -> List.rev acc
    in
    match b with
    | Omd.Heading ([], 2, Omd.Text ([], title)) :: ts ->
        { title; krs = from_headings [] ts }
    | _ -> failwith ""
end

module Project = struct
  type t = { project : string; objectives : Objective.t list }
  [@@deriving yojson]

  let of_block b =
    let rec objectives acc = function
      | Omd.Heading ([], 2, _) :: xs as t ->
          objectives (Objective.of_block t :: acc) xs
      | Omd.Heading ([], 1, _) :: _ | [] -> List.rev acc
      | _ :: xs -> objectives acc xs
    in
    match b with
    | Omd.Heading ([], 1, Omd.Text ([], project)) :: ts ->
        { project; objectives = objectives [] ts }
    | _ -> failwith "Failed to parse project"
end

type t = Project.t list [@@deriving yojson]

let of_block b =
  let rec projects acc = function
    | Omd.Heading ([], 1, _) :: xs as t ->
        projects (Project.of_block t :: acc) xs
    | [] -> List.rev acc
    | _ :: xs -> projects acc xs
  in
  projects [] b

(* Flatten OKR structure *)
module Item = struct
  type t = { project : string; objective : string; kr : Kr.t }
  [@@deriving yojson]

  let of_project : Project.t -> t list =
   fun { project; objectives } ->
    let of_objective : Objective.t -> t list =
     fun { title = objective; krs } ->
      List.map (fun kr -> { project; objective; kr }) krs
    in
    let lst = List.map of_objective objectives in
    List.concat lst
end
