(** bin_prot serializers for [Pcre.regexp].

    Round-trips a regexp through its source pattern and compile flags,
    re-running [Pcre.regexp] on read. Patterns built with custom
    chartables are not supported (same constraint as Marshal). *)

module Regexp : sig
  type t = Pcre.regexp

  include Bin_prot.Binable.S with type t := t
end
