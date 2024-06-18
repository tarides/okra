module U = Yojson.Safe.Util

let ( / ) a b = U.member b a
let ( let* ) = Result.bind

let current =
  match Build_info.V1.version () with
  | None -> "dev"
  | Some v -> Build_info.V1.Version.to_string v

let query =
  {|
{
  organization(login: "tarides") {
    repository(name: "okra") {
      latestRelease {
        name
      }
    }
  }
}
|}

let pp = Fmt.of_to_string Semver.to_string

let check ~token =
  if current = "dev" then ()
  else
    match
      let req = Get_activity.Graphql.request ~token ~query () in
      let* resp = Get_activity.Graphql.exec req in
      let json =
        resp / "data" / "organization" / "repository" / "latestRelease" / "name"
      in
      let* last_version =
        Option.to_result
          ~none:
            (`Msg
              (Fmt.str "Invalid latest release %a. Please report this bug."
                 Yojson.Safe.pp json))
        @@ Yojson.Safe.Util.to_string_option json
      in
      let* last_version =
        Option.to_result
          ~none:
            (`Msg
              (Fmt.str "Invalid latest release %s. Please report this bug."
                 last_version))
        @@ Semver.of_string last_version
      in
      let* current_version =
        Option.to_result
          ~none:
            (`Msg
              (Fmt.str "Invalid current version %s. Please report this bug."
                 current))
        @@ Semver.of_string current
      in
      let l_major, l_minor, l_patch = last_version in
      let c_major, c_minor, c_patch = current_version in
      if l_major = c_major && l_minor = c_minor && l_patch >= c_patch then Ok ()
      else
        let msg =
          Fmt.str "Invalid okra version. Expecting %a but you are using %a." pp
            last_version pp current_version
        in
        Error (`Msg msg)
    with
    | Ok x -> x
    | Error (`Msg e) ->
        Fmt.epr "Error: %s\n" e;
        exit 1
