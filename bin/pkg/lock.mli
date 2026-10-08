open Import

(** Collect all pins from all projects in the workspace. *)
val project_pins : Dune_pkg.Pin.DB.t Memo.t

(** A lock directory to write, with the configuration to solve it under and
    what a parent context contributes. For project lock directories
    [lock_dir] is the stanza found at [path] and both maps are empty; a tool
    group that inherits a context passes its own path, the parent context's
    stanza, the parent's packages it must reuse ([provided]) and all the
    parent's packages on the current platform ([parent]). *)
type lock_dir_request =
  { path : Path.t
  ; lock_dir : Workspace.Lock_dir.t option
  ; provided : Dune_pkg.Resolved_package.t Package_name.Map.t
  ; parent : Dune_pkg.Lock_dir.Pkg.t Package_name.Map.t
  }

val solve
  :  Workspace.t
  -> local_packages:Dune_pkg.Local_package.t Package_name.Map.t
  -> project_pins:Dune_pkg.Pin.DB.t
  -> solver_env_from_current_system:Dune_pkg.Solver_env.t option
  -> version_preference:Dune_pkg.Version_preference.t option
  -> lock_dirs:lock_dir_request list
  -> print_perf_stats:bool
  -> portable_lock_dir:bool
  -> unit Fiber.t

(** Command to create lock directory *)
val command : unit Cmd.t
