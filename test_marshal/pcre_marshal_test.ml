(* Marshal round-trip tests for [Pcre.regexp]. Plain stdlib assertions
   so we don't drag ounit2 into a build that doesn't need it. *)

let roundtrip rex =
  let s = Marshal.to_string rex [] in
  (Marshal.from_string s 0 : Pcre.regexp)

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
  case "default flags, no study" (fun () ->
      let rex = Pcre.regexp ~study:false "(\\w+)\\s+(\\d+)" in
      let rex' = roundtrip rex in
      assert (Pcre.pattern rex' = "(\\w+)\\s+(\\d+)");
      assert (Pcre.options rex' = Pcre.options rex);
      assert (same_matches ~rex ~rex' "foo 42  bar 7"));

  case "studied, no JIT" (fun () ->
      let rex = Pcre.regexp ~jit_compile:false "ab+c" in
      let rex' = roundtrip rex in
      assert (Pcre.jit_compiled rex' = false);
      assert (same_matches ~rex ~rex' "aabbccc abc abbbc"));

  case "studied + JIT" (fun () ->
      let rex = Pcre.regexp ~jit_compile:true "(\\d+)-(\\d+)" in
      let rex' = roundtrip rex in
      assert (Pcre.jit_compiled rex' = true);
      assert (same_matches ~rex ~rex' "1-2 33-44 555-666"));

  case "with ~limit" (fun () ->
      let rex = Pcre.regexp ~limit:12345 "x+" in
      let rex' = roundtrip rex in
      assert (Pcre.get_match_limit rex' = Some 12345);
      assert (same_matches ~rex ~rex' "xxx yy x"));

  case "with ~limit_recursion" (fun () ->
      let rex = Pcre.regexp ~limit_recursion:9999 "x+" in
      let rex' = roundtrip rex in
      assert (Pcre.get_match_limit_recursion rex' = Some 9999));

  case "embedded NUL byte in pattern" (fun () ->
      let pat = "a\x00b" in
      let rex = Pcre.regexp ~study:false pat in
      let rex' = roundtrip rex in
      assert (Pcre.pattern rex' = pat));

  case "GC-after-marshal: source freed before unmarshal" (fun () ->
      let s =
        let rex = Pcre.regexp "hello" in
        Marshal.to_string rex []
      in
      Gc.full_major ();
      Gc.full_major ();
      let rex' : Pcre.regexp = Marshal.from_string s 0 in
      assert (Pcre.pattern rex' = "hello"));

  case "custom chartables raises Failure" (fun () ->
      let chtables = Pcre.maketables () in
      let rex = Pcre.regexp ~chtables "abc" in
      match Marshal.to_string rex [] with
      | exception Failure _ -> ()
      | _ -> assert false);

  print_endline "all marshal tests passed"
