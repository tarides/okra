(lang dune 2.8)
(name okra)

(generate_opam_files true)

(license ISC)
(authors "Magnus Skjegstad")
(maintainers "magnus@skjegstad.com")

(package
 (name okra-bin)
 (synopsis "Report parsing executable")
 (description "An executable to be used for report parsing")
 (depends
  (alcotest :with-test)
  (mdx :with-test)
  okra
  cmdliner
  bos
  (yaml (>= 3.0))
  (cohttp-lwt-unix (>= 4.0.0))
  tls))

(package
 (name okra)
 (synopsis "Report parsing prototypes")
 (description "A library of tools for report parsing")
 (depends
  (ocaml (>= 4.07))
  (alcotest :with-test)
  fmt
  get-activity
  calendar
  (omd (>= 2.0))))
(using mdx 0.1)
