open Import

(** Collect all pins from all projects in the workspace. *)
val project_pins : Dune_pkg.Pin.DB.t Memo.t

val solve
  :  Workspace.t
  -> local_packages:Dune_pkg.Local_package.t Package_name.Map.t
  -> project_pins:Dune_pkg.Pin.DB.t
  -> solver_env_from_current_system:Dune_pkg.Solver_env.t option
  -> version_preference:Dune_pkg.Version_preference.t option
  -> lock_dirs:
       (Path.t
       * Workspace.Lock_dir.t option
       * Dune_pkg.Resolved_package.t Package_name.Map.t)
         list
       (** Each lock directory to write, with the configuration to solve it
           under and the packages provided from outside it. For project lock
           directories the configuration is the stanza found at that path and
           nothing is provided; a tool group that inherits a context passes
           its own path, the parent context's stanza, and the parent's
           packages it reuses. *)
  -> print_perf_stats:bool
  -> portable_lock_dir:bool
  -> unit Fiber.t

(** Command to create lock directory *)
val command : unit Cmd.t
