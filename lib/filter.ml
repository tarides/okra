module StringSet = Set.Make (String)

let string_set l =
  List.fold_left
    (fun acc e -> StringSet.add (String.uppercase_ascii e) acc)
    StringSet.empty l

type t = {
  include_projects : StringSet.t;
  exclude_projects : StringSet.t;
  include_objectives : StringSet.t;
  exclude_objectives : StringSet.t;
  include_krs : StringSet.t;
  exclude_krs : StringSet.t;
  include_engineers : StringSet.t;
  exclude_engineers : StringSet.t;
}

let string_of_kr = function
  | KR.No_KR -> "NO KR"
  | New_KR -> "NEW KR"
  | ID s -> String.uppercase_ascii s

let kr_of_string s =
  match String.uppercase_ascii s with
  | "NEW KR" | "NEW WI" -> KR.New_KR
  | "NO KR" | "NO WI" -> No_KR
  | _ -> ID s

let kr_set l =
  List.fold_left
    (fun acc e -> StringSet.add (string_of_kr e) acc)
    StringSet.empty l

let is_empty f =
  StringSet.is_empty f.include_projects
  && StringSet.is_empty f.exclude_projects
  && StringSet.is_empty f.include_objectives
  && StringSet.is_empty f.exclude_objectives
  && StringSet.is_empty f.include_krs
  && StringSet.is_empty f.exclude_krs
  && StringSet.is_empty f.include_engineers
  && StringSet.is_empty f.exclude_engineers

let union t1 t2 =
  {
    include_projects = StringSet.union t1.include_projects t2.include_projects;
    exclude_projects = StringSet.union t1.exclude_projects t2.exclude_projects;
    include_objectives =
      StringSet.union t1.include_objectives t2.include_objectives;
    exclude_objectives =
      StringSet.union t1.exclude_objectives t2.exclude_objectives;
    include_krs = StringSet.union t1.include_krs t2.include_krs;
    exclude_krs = StringSet.union t1.exclude_krs t2.exclude_krs;
    include_engineers =
      StringSet.union t1.include_engineers t2.include_engineers;
    exclude_engineers =
      StringSet.union t1.exclude_engineers t2.exclude_engineers;
  }

let v ?(include_projects = []) ?(exclude_projects = [])
    ?(include_objectives = []) ?(exclude_objectives = []) ?(include_krs = [])
    ?(exclude_krs = []) ?(include_engineers = []) ?(exclude_engineers = []) () =
  let include_projects = string_set include_projects in
  let exclude_projects = string_set exclude_projects in
  let include_objectives = string_set include_objectives in
  let exclude_objectives = string_set exclude_objectives in
  let include_krs = kr_set include_krs in
  let exclude_krs = kr_set exclude_krs in
  let include_engineers = string_set include_engineers in
  let exclude_engineers = string_set exclude_engineers in
  {
    include_projects;
    exclude_projects;
    include_objectives;
    exclude_objectives;
    include_krs;
    exclude_krs;
    include_engineers;
    exclude_engineers;
  }

let empty = v ()

let apply f (t : Report.t) =
  if is_empty f then t
  else
    let new_t = Report.empty () in
    Report.iter
      (fun (kr : KR.t) ->
        let p = String.uppercase_ascii kr.project in
        let o = String.uppercase_ascii kr.objective in
        let id = string_of_kr kr.KR.id in
        let es =
          Hashtbl.to_seq kr.time_per_engineer
          |> Seq.map fst
          |> List.of_seq
          |> string_set
        in
        let skip () = () in
        let add () =
          if
            StringSet.is_empty f.include_engineers
            && StringSet.is_empty f.exclude_engineers
          then Report.add new_t kr
          else
            let time_entries =
              List.fold_left
                (fun acc line ->
                  let l =
                    List.fold_left
                      (fun l (e, d) ->
                        let e' = String.uppercase_ascii e in
                        if StringSet.mem e' f.include_engineers then (e, d) :: l
                        else if StringSet.mem e' f.exclude_engineers then l
                        else if StringSet.is_empty f.include_engineers then
                          (e, d) :: l
                        else l)
                      [] line
                  in
                  if l = [] then acc else List.rev l :: acc)
                [] kr.time_entries
              |> List.rev
            in
            if time_entries = [] then ()
            else if time_entries = kr.time_entries then Report.add new_t kr
            else
              let work =
                Item.
                  [
                    Paragraph
                      (Concat
                         [
                           Text
                             "WARNING: the following items might cover more \
                              work than what the time entries indicate.";
                         ]);
                  ]
                :: kr.work
              in
              let kr =
                KR.v ~project:kr.project ~objective:kr.objective ~title:kr.title
                  ~time_entries ~id:kr.id work
              in
              Report.add new_t kr
        in
        let check x (incl, excl) =
          match StringSet.(is_empty incl, is_empty excl) with
          | true, true -> true
          | false, true -> StringSet.mem x incl
          | true, false -> not (StringSet.mem x excl)
          | false, false -> StringSet.(mem x incl && not (mem x excl))
        in
        let check_set s (incl, excl) =
          match StringSet.(is_empty incl, is_empty excl) with
          | true, true -> true
          | false, true -> not StringSet.(is_empty (inter s incl))
          | true, false -> StringSet.(is_empty (inter s excl))
          | false, false ->
              StringSet.(
                (not (is_empty (inter s incl))) && is_empty (inter s excl))
        in
        if
          check p (f.include_projects, f.exclude_projects)
          && check o (f.include_objectives, f.exclude_objectives)
          && check id (f.include_krs, f.exclude_krs)
          && check_set es (f.include_engineers, f.exclude_engineers)
        then add ()
        else skip ())
      t;
    new_t
