open Import

(** [dune tools lock <group>]: solve a tool group declared in dune-workspace
    and write its lock directory under [_build]. Groups that inherit a
    context are not supported yet. *)
val command : unit Cmd.t
