(* bin_prot round-trip tests for [Pcre.regexp]. *)

let roundtrip rex =
  let buf =
    Bin_prot.Utils.bin_dump Pcre_bin_prot.Regexp.bin_writer_t rex
  in
  let pos_ref = ref 0 in
  let r = Pcre_bin_prot.Regexp.bin_read_t buf ~pos_ref in
  assert (!pos_ref = Bigarray.Array1.dim buf);
  r

let same_matches ~rex ~rex' subj =
  Pcre.extract_all ~rex subj = Pcre.extract_all ~rex:rex' subj

let case name f =
  try
    f ();
    Printf.printf "[ OK ] %s\n" name
  with e ->
    Printf.printf "[FAIL] %s: %s\n" name (Printexc.to_string e);
    exit 1

let () =
  case "default flags, studied no JIT" (fun () ->
      let rex = Pcre.regexp "(\\w+)\\s+(\\d+)" in
      let rex' = roundtrip rex in
      assert (Pcre.pattern rex' = "(\\w+)\\s+(\\d+)");
      assert (same_matches ~rex ~rex' "foo 42  bar 7"));

  case "studied + JIT" (fun () ->
      let rex = Pcre.regexp ~jit_compile:true "(\\d+)-(\\d+)" in
      let rex' = roundtrip rex in
      assert (Pcre.jit_compiled rex' = true);
      assert (same_matches ~rex ~rex' "1-2 33-44 555-666"));

  case "with ~limit and ~limit_recursion" (fun () ->
      let rex = Pcre.regexp ~limit:777 ~limit_recursion:888 "x+" in
      let rex' = roundtrip rex in
      assert (Pcre.get_match_limit rex' = Some 777);
      assert (Pcre.get_match_limit_recursion rex' = Some 888));

  case "embedded NUL byte in pattern" (fun () ->
      let pat = "a\x00b" in
      let rex = Pcre.regexp pat in
      let rex' = roundtrip rex in
      assert (Pcre.pattern rex' = pat));

  case "icflag round-trip" (fun () ->
      let flags = [ `CASELESS; `MULTILINE ] in
      let rex = Pcre.regexp ~flags "Foo" in
      let rex' = roundtrip rex in
      assert (Pcre.options rex' = Pcre.options rex);
      assert (same_matches ~rex ~rex' "FOO\nfoo BAR"));

  print_endline "all bin_prot tests passed"
