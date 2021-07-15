open Omd

exception No_time_found of string
exception Multiple_time_entries of string
exception KR_title_id_mismatch of string

(* Type for sanitized post-ast version *)
type okr_entry = {
  counter : int;
  proj : string;
  obj : string;
  kr_title : string;
  kr_id : string;
  time_entries : string list;
  time_per_engineer : (string, float) Hashtbl.t;
  work : string list;
}

(* Types for parsing the AST *)
type okr_t =
  | O of string (* Objective name, without lead *)
  | Proj of string (* Project name / pillar *)
  | KR of string (* Full name of KR, with ID *)
  | KR_id of string (* ID of KR *)
  | KR_title of string (* Title without ID, tech lead *)
  | Work of string list (* List of work items *)
  | Time of string (* Time entry *)
  | Counter of int (* Increasing counter to be able to sort multiple entries by time *)

type okr_ht = (string, okr_t list list) Hashtbl.t
type store_ht = {
  okr_ht : okr_ht; } (* Todo this doesn't have to be two types okr_ht/store_ht anymore *)

let okr_re = Str.regexp "\\(.+\\) (\\([a-zA-Z]+[0-9]+\\))$" (* Header: This is a KR (KR12) *)
let obj_re = Str.regexp "\\(.+\\) (\\([a-zA-Z ]+\\))$"      (* Header: This is an objective (Tech lead name) *)
let new_okr_re = obj_re
let tim_re = Str.regexp "@\\([a-zA-Z0-9]+\\) (\\([0-9.]+\\) days?)$" (* @[github-handle] ([float] day/days) *)
let tim_split_re = Str.regexp " ?, ?" (* Split on , surrounded by zero or more whitespace *)

let check_valid_time_block tb =
  match tb with
  | [{bl_desc=Paragraph {il_desc=Text s;_}; _}] -> String.get (String.trim s) 0 = '@'
  | _ -> false

let is_suffix suffix s =
  (String.length s) >= (String.length suffix) &&
  let suffix = String.uppercase_ascii suffix in
  let s = String.uppercase_ascii s in
  String.equal suffix (String.sub s ((String.length s) - (String.length suffix))  (String.length suffix))

let parse_okr_title s =
  (* todo: could match on ??) too? *)
  if (is_suffix "(new kr)" s) ||
     (is_suffix "(new okr)" s) then begin
    match (Str.string_match new_okr_re s 0) with
    | false -> None
    | true -> Some (String.trim (Str.matched_group 1 s), "new KR")
  end else begin
    match (Str.string_match okr_re s 0) with
    | false -> None
    | true -> Some (String.trim (Str.matched_group 1 s), String.trim (Str.matched_group 2 s))
  end

let hashtbl_keys ht =
  List.sort_uniq compare (List.of_seq (Hashtbl.to_seq_keys ht))

let is_prefix prefix s =
  (String.length s) >= (String.length prefix) &&
  let prefix = String.uppercase_ascii prefix in
  let s = String.uppercase_ascii s in
  String.equal prefix (String.sub s 0 (String.length prefix))

let get_proj_list store =
  (* iterate over ht *)
  let keys = hashtbl_keys store.okr_ht in
  List.sort_uniq compare (
    List.concat (
      List.map (fun key ->
          let okr_list = List.concat (Hashtbl.find store.okr_ht key) in
          List.concat (
            List.map (fun el -> match el with
              | Proj s -> [s]
              | _ -> []) okr_list)
        ) keys))

let string_of_okr okr =
  let l = List.map (fun xs ->
    match (xs) with
    | Proj s -> Printf.sprintf "P: %s" s
    | O s -> Printf.sprintf "O: %s" s
    | KR s -> Printf.sprintf "KR: %s" s
    | KR_id s -> Printf.sprintf "KR id: %s" s
    | KR_title s -> Printf.sprintf "KR title: %s" s
    | Work w -> String.concat ", " (List.map (fun e -> Printf.sprintf "W: %s" e) w)
    | Time _ -> "Time: <not shown>"
    | Counter c -> Printf.sprintf "Cnt: %d" c) okr
  in
  String.concat ", " l

let store_result store okr_list =
  let key1 =
    let f = List.find_opt (fun xs ->
        match (xs) with
        | KR_title _ -> true
        | _ -> false) okr_list in
    match (f) with
    | Some (KR_title t) -> t
    | _ -> "Unknown"
  in
  let key = Printf.sprintf "%s" (String.uppercase_ascii key1) in
  let has_time =
    match (List.find_opt (fun xs ->
        match (xs) with
        | Time _ -> true
        | _ -> false) okr_list) with
    | None -> false
    | Some _ -> true
  in
        match has_time with
  | false -> Printf.printf "WARNING: Ignored %s\n" (string_of_okr okr_list)
  | true -> (match (Hashtbl.find_opt store.okr_ht key) with
      | None -> Hashtbl.add store.okr_ht key [okr_list]
      | Some x -> Hashtbl.replace store.okr_ht key ( x @ [okr_list]))

let rec inline {il_desc; _} =
  match il_desc with
  | Concat xs -> List.concat (List.map inline xs)
  | Text s -> [s]
  | Emph s -> "*" :: inline s @ ["*"]
  | Strong s -> "**" :: inline s @ ["**"]
  | Code s -> ["`"; s; "`"]
  | Hard_break -> ["\n\n"]
  | Soft_break -> ["\n"]
  | Link {label; destination; _} -> "[" :: inline label @ ["](" ; destination ; ")"]
  | Html _ -> ["**html-ignored**"]
  | Image _ -> ["**img ignored**"]

let rec block {bl_desc; _} =
  match bl_desc with
  | Paragraph x -> inline x @ ["\n"]
  | List (_, _, bls) -> List.concat (List.map (fun xs -> "        - " :: List.concat(List.map block xs)) bls)
  | Blockquote x -> "> " :: List.concat (List.map block x)
  | Thematic_break -> ["*thematic-break-ignored*"];
  | Heading (level, text) -> String.make level '#' :: inline text @ ["\n"]
  | Code_block (info, _) -> ["```" ;info ; "```"]
  | Html_block _ -> ["*html-ignored*"]
  | Definition_list _ -> ["*def-list-ignored*"]

let block_okr {bl_desc; _} =
  match bl_desc with
  | Paragraph x ->
    let okr_title = String.trim (String.concat "" (inline x)) in
    (match parse_okr_title okr_title with
    | None -> [KR okr_title; KR_title okr_title]
    | Some (title, id) -> [KR okr_title; KR_title title; KR_id id])
  | List (_, _, bls) ->
    if (List.length (List.filter check_valid_time_block bls)) > 1 then
      (* This is fatal, as we can miss tracked time if this occurs -- time should always be summarised in first entry *)
      raise (Multiple_time_entries "Multiple time entries found")
    else ();
    let tb = List.hd bls in (* Assume first block is time if present, and ... *)
    if check_valid_time_block tb then (* verify that this is true *)
    begin
      let time_s = String.concat "" (List.map (fun xs -> String.concat "" (block xs)) tb) in
      let work_items = Work (List.map (fun xs -> String.concat "" (List.concat (List.map block xs))) (List.tl bls)) in
      [Time time_s; work_items]
    end else
      []
  | _ -> []


let parse_obj s =
  match (Str.string_match obj_re s 0) with
  | false -> None
  | true -> Some (Str.matched_group 1 s, Str.matched_group 2 s)

let strip_obj_lead s =
  match (Str.string_match obj_re (String.trim s) 0) with
  | false -> s
  | true -> (Str.matched_group 1 s)

let print_okrs okr_list =
  (* Just print O/KR from first item *)
  List.iter (fun el -> match el with
    | Proj s -> Printf.printf "\n# %s\n" s
    | O s -> Printf.printf "\n## %s\n" s
    | KR s -> Printf.printf "\n- %s\n" s
    | _ -> ()) (List.hd okr_list);
  (* Just find time *)
  let ht_t = Hashtbl.create 7 in
  let _ = List.map (fun elements ->
    List.iter (fun el -> match el with
      | Time t_ ->
        Printf.printf "    - + %s" t_;
        (* todo this shouldn't happen when printing, but earlier *)
        (* split on @, then extract first word and any float after *)
        let t_split = Str.split (Str.regexp "@+") t_ in
        List.iter (fun s ->
          match (Str.string_match (Str.regexp "^\\([a-zA-Z0-9-]+\\)[^0-9]+\\([0-9.]+\\)" ) s 0) with
          | false -> ()
          | true -> begin
            let user = Str.matched_group 1 s in
            (* todo: let this conversion raise an exception, would be nice to exit more cleanly, but it should be fatal *)
            let days = Float.of_string (Str.matched_group 2 s) in
            (*Printf.printf "-  + @%s (%.1f days)\n" user days;*)
            Hashtbl.add ht_t user days
          end
        ) t_split
      | _ -> ()) elements) okr_list in
  (* Sum and print time *)
  Printf.printf "    - = ";
  List.iter (fun key ->
      let sum = List.fold_left (fun a b -> Float.add a b) 0.0 (Hashtbl.find_all ht_t key) in
      Printf.printf "@%s (%.2f days) " key sum
    ) (hashtbl_keys ht_t);
  Printf.printf "\n";
  (* Just print work *)
  let _ = List.map (fun elements ->
      List.iter (fun el -> match el with
        | Work w -> List.iter (fun w_ -> Printf.printf "    - %s" w_) w
        | _ -> ()) elements) okr_list
  in ()

let current_o = ref "None"
let current_proj = ref "Unknown"
let current_counter = ref 0

let process_okr_block ht hd tl =
  (* peek at each block in list, consume if match - otherwise return full list for regular processing*)
  let {bl_desc; _} = hd in
  match bl_desc with
        | Heading (_, {il_desc;_}) -> begin
                let title = (match il_desc with
      (* Display header with level, strip lead from objectives if present *)
      | Text s -> (strip_obj_lead s)
      | _ -> "None") in
    (* remember last object title seen - works if Os have not been renamed in a set of files *)
    current_o := title;
    tl
        end
  | List (_, _, bls) ->
    let _ = List.map (fun xs ->
      let okr_list = List.concat (List.map block_okr xs) in
      (*if List.length okr_list = 3 then
        okr_list
      else (* return empty list if it doesn't include Time/Work/OKR *)
        okr_list) bls in*)
      store_result ht ([Proj !current_proj ; O !current_o ; Counter !current_counter] @ okr_list)) bls in
      current_counter := !current_counter + 1;
    tl
  | _ -> tl

let process_entry ht hd tl =
  (* Find project level headers *)
  let {bl_desc; _} = hd in
        (match bl_desc with
        | Heading (level, {il_desc;_}) -> begin
                (match level, il_desc with
                (* Display header with level, strip lead from objectives if present *)
                | 1, Text s -> current_proj := s
                | _, _ -> ());
        end
        | _ -> ());
        process_okr_block ht hd tl

let rec process ht ast =
  match ast with
  | [hd] -> process ht (process_entry ht hd [])
  | hd :: tl -> process ht (process_entry ht hd tl)
  | [] -> ()

let has_proj okr_list proj =
  let m = List.find_all (fun f ->
    match f with
    | Proj s -> Printf.printf "%s=%s\n" s proj;(compare s proj = 0)
    | _ -> false) okr_list in
  (List.length m) > 0

let filter_proj okr_ll proj =
  List.filter (fun f -> has_proj f proj) okr_ll

let okr_entry_of_okr_list okr_list =
  (* This function expects a list of entries for the same KR, typically
     corresponding to a set of weekly reports. Each list item will consist of
     a list of okr_t items, which provides time, work items etc for this entry.

     This function will aggregate all entries for the same KR in an
     okr_entry record for easier processing later.
        *)

  let okr_proj = ref "" in
  let okr_obj = ref "" in
  let okr_kr_title = ref "" in
  let okr_kr_id = ref "" in
  let okr_counter = ref 0 in

  (* Assume each item in list has the same O/KR/Proj, so just parse the first one *)
  (* todo we could sanity check here by verifying that every entry has the same KR/O *)
  List.iter (fun el -> match el with
    | Proj s -> okr_proj := s
    | O s -> okr_obj := s
    | KR_title s -> okr_kr_title := s
    | KR_id s -> okr_kr_id := String.uppercase_ascii s
    | Counter x -> okr_counter := x
    | _ -> ()) (List.hd okr_list);

  (* Find all the time records and store in hashtbl keyed by engineer + original *)
  let okr_time_entries = ref [] in
  let ht_t = Hashtbl.create 7 in
  List.iter (fun elements ->
    List.iter (fun el -> match el with
      | Time t_ ->
        (* Store the string entry to be able to check correctness later *)
        okr_time_entries := !okr_time_entries @ [t_];
        (* split on @, then extract first word and any float after *)
        let t_split = Str.split (Str.regexp "@+") t_ in
        List.iter (fun s ->
          match (Str.string_match (Str.regexp "^\\([a-zA-Z0-9-]+\\)[^0-9]+\\([0-9.]+\\)" ) s 0) with
          | false -> ()
          | true -> begin
            let user = Str.matched_group 1 s in
            (* todo: let this conversion raise an exception, would be nice to exit more cleanly, but it should be fatal *)
            let days = Float.of_string (Str.matched_group 2 s) in
            Hashtbl.add ht_t user days
          end
        ) t_split
      | _ -> ()) elements) okr_list;

  (* Sum time per engineer *)
  let time_per_engineer = Hashtbl.create 7 in
  List.iter (fun key ->
       let sum = List.fold_left (fun a b -> Float.add a b) 0.0 (Hashtbl.find_all ht_t key) in
       Hashtbl.replace time_per_engineer key sum
      ) (hashtbl_keys ht_t);

  (* Add work items in order, concat all the lists *)
  let work = List.concat (
        List.map (fun elements ->
          List.concat (
            List.map (fun el -> match el with
              | Work w -> w
              | _ -> []) elements)
          ) okr_list) in

  (* Construct final entry *)
  { counter = !okr_counter;
    proj = !okr_proj;
    obj = !okr_obj;
    kr_title = !okr_kr_title;
    kr_id = !okr_kr_id;
    time_entries = !okr_time_entries;
    time_per_engineer;
    work; }

let () =
  let store = {okr_ht=Hashtbl.create 100}  in
  let md = Omd.of_channel stdin in
  process store md;

  (*Hashtbl.iter (fun _ v ->
    print_okrs v) store.okr_ht*)


  let v = List.map okr_entry_of_okr_list (List.of_seq (Hashtbl.to_seq_values store.okr_ht)) in
  let okr_compare a b =
    if compare a.proj b.proj = 0 then (* compare on project first *)
    begin
      if compare a.obj b.obj = 0 then (* then obj if proj equal *)
      begin
        (* Check if KR IDs are the same --if one of the KR IDs are blank, compare on title instead *)
        let compare_kr_id =
          if (a.kr_id = "") || (b.kr_id = "") ||
             (a.kr_id = "NEW KR") || (b.kr_id = "NEW KR") ||
             (a.kr_id = "NEW OKR") || (b.kr_id = "NEW OKR") then
          begin
            compare a.kr_title b.kr_title
          end else begin
            compare a.kr_id b.kr_id
          end
        in
        (* If KRs match, check counter *)
        if compare_kr_id = 0 then
        begin
          compare a.counter b.counter
        end else
          compare_kr_id
      end else
        compare a.obj b.obj
    end else
      compare a.proj b.proj
  in
  let c_proj = ref "" in
  let c_obj = ref "" in
  let c_kr_id = ref "" in
  let c_kr_title = ref "" in
  List.iter (fun e ->
    if (e.proj <> !c_proj) then begin
      Printf.printf "\n# %s\n" e.proj;
      c_proj := e.proj
    end else ();
    if (e.obj <> !c_obj) then begin
      Printf.printf "\n## %s\n" e.obj;
      c_obj := e.obj
    end else ();
    if (e.kr_id <> !c_kr_id) || (e.kr_title <> !c_kr_title) then begin
      Printf.printf "\n- %s (%s)\n" e.kr_title e.kr_id;
      c_kr_title := e.kr_title;
      c_kr_id := e.kr_id
    end else ();
    List.iter (fun s -> Printf.printf "    - + %s" s) e.time_entries;
    Printf.printf "    - = ";
    Hashtbl.iter (fun s v -> Printf.printf "@%s (%.2f days) " s v) e.time_per_engineer;
    Printf.printf "\n";
    List.iter (fun s -> Printf.printf "    - %s" s) e.work)
    (List.sort okr_compare v)
