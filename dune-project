(lang dune 2.7)

(name pcre)

(generate_opam_files true)

(source
 (github mmottl/pcre-ocaml))

(license "LGPL-2.1-or-later WITH OCaml-LGPL-linking-exception")

(homepage "https://mmottl.github.io/pcre-ocaml")

(documentation "https://mmottl.github.io/pcre-ocaml/api")

(maintainers "Markus Mottl <markus.mottl@gmail.com>")

(authors "Markus Mottl <markus.mottl@gmail.com>")

(package
 (name pcre)
 (synopsis "Bindings to the Perl Compatibility Regular Expressions library")
 (description
   "pcre-ocaml offers library functions for string pattern matching and\nsubstitution, similar to the functionality offered by the Perl language.")
 (depends
  (ocaml
   (>= 4.08))
  dune-compiledb
  dune-configurator
  (conf-libpcre :build)
  (ounit2 :with-test)))

(package
 (name pcre_bin_prot)
 (synopsis "bin_prot serializers for Pcre.regexp")
 (description
   "Provides Bin_prot.Type_class.t for Pcre.regexp by round-tripping\nthrough the source pattern + compile flags and recompiling on read.")
 (depends
  (ocaml
   (>= 4.08))
  (pcre
   (= :version))
  bin_prot
  ppx_bin_prot))
