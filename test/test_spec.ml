open Okra

let spec =
  Alcotest.of_pp (fun ppf t -> Yojson.Safe.pp ppf (Okra.Spec.to_yojson t))

let items =
  Alcotest.of_pp (fun ppf t ->
      Fmt.pf ppf "%a" (Fmt.list Yojson.Safe.pp)
        (List.map Okra.Spec.Item.to_yojson t))

let test =
  {|
# Okra: Objectives

## Release Okra to the World

### Active
- Add spec parsing to okra (Patrick Ferris) (OKRA1)

### Scheduled (Q3 2021)
- Add default work items for projects (Patrick Ferris) (OKRA3)

### Unscheduled
- Calendar bindings for Okra (Magnus Skjegstad) (OKRA2)

## Okra Web

### Scheduled (Q3 2021)
- Simplify and make it useful (Patrick Ferris) (OKRA4)
|}

let projects =
  Spec.
    {
      Project.project = "Okra: Objectives";
      objectives =
        [
          Objective.
            {
              title = "Release Okra to the World";
              krs =
                Kr.
                  [
                    {
                      title = "Add spec parsing to okra";
                      owner = Some "Patrick Ferris";
                      ident = "OKRA1";
                      status = Active;
                    };
                    {
                      title = "Add default work items for projects";
                      owner = Some "Patrick Ferris";
                      ident = "OKRA3";
                      status = Scheduled (Quarterly (`Q3, 2021));
                    };
                    {
                      title = "Calendar bindings for Okra";
                      owner = Some "Magnus Skjegstad";
                      ident = "OKRA2";
                      status = Unscheduled;
                    };
                  ];
            };
          {
            title = "Okra Web";
            krs =
              [
                {
                  title = "Simplify and make it useful";
                  owner = Some "Patrick Ferris";
                  ident = "OKRA4";
                  status = Scheduled (Quarterly (`Q3, 2021));
                };
              ];
          };
        ];
    }

let test_spec_parse () =
  let md = Omd.of_string test in
  let actual = Spec.of_block md in
  Alcotest.(check spec) "same spec" [ projects ] actual

let test_project_to_items () =
  let actual = Spec.Item.of_project projects in
  let expected =
    [
      {
        Okra.Spec.Item.project = "Okra: Objectives";
        objective = "Release Okra to the World";
        kr =
          {
            Okra.Spec.Kr.title = "Add spec parsing to okra";
            owner = Some "Patrick Ferris";
            ident = "OKRA1";
            status = Okra.Spec.Kr.Active;
          };
      };
      {
        Okra.Spec.Item.project = "Okra: Objectives";
        objective = "Release Okra to the World";
        kr =
          {
            Okra.Spec.Kr.title = "Add default work items for projects";
            owner = Some "Patrick Ferris";
            ident = "OKRA3";
            status = Okra.Spec.Kr.Scheduled (Okra.Spec.Kr.Quarterly (`Q3, 2021));
          };
      };
      {
        Okra.Spec.Item.project = "Okra: Objectives";
        objective = "Release Okra to the World";
        kr =
          {
            Okra.Spec.Kr.title = "Calendar bindings for Okra";
            owner = Some "Magnus Skjegstad";
            ident = "OKRA2";
            status = Okra.Spec.Kr.Unscheduled;
          };
      };
      {
        Okra.Spec.Item.project = "Okra: Objectives";
        objective = "Okra Web";
        kr =
          {
            Okra.Spec.Kr.title = "Simplify and make it useful";
            owner = Some "Patrick Ferris";
            ident = "OKRA4";
            status = Okra.Spec.Kr.Scheduled (Okra.Spec.Kr.Quarterly (`Q3, 2021));
          };
      };
    ]
  in
  Alcotest.(check items) "same items" expected actual

let tests =
  [
    ("Parse_spec", `Quick, test_spec_parse);
    ("Spec_items", `Quick, test_project_to_items);
  ]
