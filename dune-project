(lang dune 3.7)
(name okra)

(generate_opam_files true)

(using mdx 0.3)
(cram enable)

(license ISC)
(authors "Magnus Skjegstad")
(maintainers "Guillaume Petiot <guillaume@tarides.com>")
(source (github tarides/okra))

(package
 (name okra)
 (synopsis "Report parsing executable")
 (description "An executable to be used for report parsing")
 (depends
  (alcotest (and (>= 1.7.0) :with-test))
  (mdx (and (>= 2.2.1) :with-test))
  (logs (>= 0.7.0))
   xdg
  (fmt (>= 0.9.0))
  (okra-lib (= :version))
  (cmdliner (>= 1.1.1))
  (ppx_deriving_yaml (>= 0.2.0))
  bos
  dune-build-info
  (yaml (>= 3.0))
  (cohttp-lwt-unix (>= 5.0.0))))

(package
 (name okra-lib)
 (synopsis "Report parsing prototypes")
 (description "A library of tools for report parsing")
 (depends
  (ocaml (>= 4.10))
  (alcotest (and (>= 1.7.0) :with-test))
  (logs (>= 0.7.0))
  (fmt (>= 0.9.0))
  (lwt (>= 5.6.1))
  xdg
  (get-activity-lib (>= 0.2.0))
  (gitlab (>= 0.1.7))
  (calendar (>= 3.0.0))
  (csv (>= 2.4))
  (omd (>= 2.0.0~alpha3))))
