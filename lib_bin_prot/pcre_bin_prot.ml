open Bin_prot.Std

type regexp_repr = {
  pattern : string;
  options : int;
  jit_compile : bool;
  match_limit : int option;
  match_limit_recursion : int option;
}
[@@deriving bin_io]

let to_repr r =
  {
    pattern = Pcre.pattern r;
    options = Pcre.int_of_icflag (Pcre.options r);
    jit_compile = Pcre.jit_compiled r;
    match_limit = Pcre.get_match_limit r;
    match_limit_recursion = Pcre.get_match_limit_recursion r;
  }

let of_repr { pattern; options; jit_compile; match_limit; match_limit_recursion }
    =
  Pcre.regexp
    ~iflags:(Pcre.icflag_of_int options)
    ~jit_compile ?limit:match_limit
    ?limit_recursion:match_limit_recursion pattern

module Regexp = struct
  type t = Pcre.regexp

  let bin_shape_t = bin_shape_regexp_repr
  let bin_size_t t = bin_size_regexp_repr (to_repr t)
  let bin_write_t buf ~pos t = bin_write_regexp_repr buf ~pos (to_repr t)
  let bin_read_t buf ~pos_ref = of_repr (bin_read_regexp_repr buf ~pos_ref)

  let __bin_read_t__ _buf ~pos_ref _vint =
    Bin_prot.Common.raise_variant_wrong_type "Pcre_bin_prot.Regexp.t" !pos_ref

  let bin_writer_t : t Bin_prot.Type_class.writer =
    { size = bin_size_t; write = bin_write_t }

  let bin_reader_t : t Bin_prot.Type_class.reader =
    { read = bin_read_t; vtag_read = __bin_read_t__ }

  let bin_t : t Bin_prot.Type_class.t =
    { shape = bin_shape_t; writer = bin_writer_t; reader = bin_reader_t }
end
