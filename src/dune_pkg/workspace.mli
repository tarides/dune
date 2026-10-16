open Import

module Repository : sig
  type t

  val opam_url : t -> Loc.t * OpamUrl.t
  val hash : t -> int
  val to_dyn : t -> Dyn.t
  val equal : t -> t -> bool
  val upstream : t
  val overlay : t
  val relocatable : t
  val binary_packages : t
  val decode : t Decoder.t

  module Name : sig
    type t

    val equal : t -> t -> bool
    val compare : t -> t -> ordering
    val pp : t -> 'a Pp.t

    include Stringlike with type t := t
    include Comparable_intf.S with type key := t
  end

  val name : t -> Name.t
end

val tools_lock_dir_name : string
val dev_tool_path_to_source_dir : Path.External.t -> Path.Source.t
val tool_path_to_source_dir : Path.External.t -> Path.Source.t

(** Maps the external path of a dev tool or tool group lock dir to its source
    spelling, choosing the mapper by the path's first component under _build. *)
val external_lock_dir_to_source_dir : Path.External.t -> Path.Source.t
