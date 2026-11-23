open Import

(** Collect all pins from all projects in the workspace. *)
val project_pins : Dune_pkg.Pin.DB.t Memo.t

(** Contains the details [solve] needs to know to generate a lock_directory.
  [solve] takes a list of [lock_dir_request] and generates a lock directory for
  all of them. *)
type lock_dir_request =
  { (* The physical location lock directory gets written to. It's normally dune.lock for the project. *)
    path : Path.t
    (* The definition of lock_dir stanza associated to this path. This may or
        may not be defined in the workspace. For instance, for an inheriting
        tool group it's not defined separately and the parent's configuration is
        where the definition lives. *)
  ; lock_dir : Workspace.Lock_dir.t option
    (* Packages that are marked explicitly as shared packages. The solver is not allowed to choose a different one. *)
  ; provided : Dune_pkg.Resolved_package.t Package_name.Map.t
    (* Packages from the parent context which are given as a preference to the solver. The solver can choose a different
      version if it is not able to satisfy the preferences. *)
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
