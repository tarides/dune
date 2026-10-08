open Import

(** [dune tools lock <group>]: solve a tool group declared in dune-workspace
    and write its lock directory under [_build]. A group that inherits a
    context is solved on top of that context's lock directory and locks only
    the packages it adds or resolves differently. *)
val command : unit Cmd.t
