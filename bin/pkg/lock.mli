open Import

(** Collect all pins from all projects in the workspace. *)
val project_pins : Dune_pkg.Pin.DB.t Memo.t

val solve
  :  Workspace.t
  -> local_packages:Dune_pkg.Local_package.t Package_name.Map.t
  -> project_pins:Dune_pkg.Pin.DB.t
  -> solver_env_from_current_system:Dune_pkg.Solver_env.t option
  -> version_preference:Dune_pkg.Version_preference.t option
  -> lock_dirs:(Path.t * Workspace.Lock_dir.t option) list
       (** Each lock directory to write, paired with the configuration to
           solve it under. For project lock directories this is the stanza
           found at that path; a tool group that inherits a context passes
           its own path with the parent context's stanza. *)
  -> print_perf_stats:bool
  -> portable_lock_dir:bool
  -> unit Fiber.t

(** Command to create lock directory *)
val command : unit Cmd.t
