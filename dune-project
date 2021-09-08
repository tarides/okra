(lang dune 2.8)
(name okra)

(generate_opam_files true)

(license ISC)
(authors "Magnus Skjegstad")
(maintainers "magnus@skjegstad.com")

(package
 (name okra)
 (synopsis "Report parsing prototypes")
 (description "")
 (depends
  (ocaml (>= 4.07))
  (alcotest :with-test)
  fmt
  cmdliner
  bos
  get-activity
  calendar
  (yaml (>= 3.0))
  (omd (>= 2.0))))
(using mdx 0.1)
