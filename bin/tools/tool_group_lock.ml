open Import

let find_group (workspace : Workspace.t) name =
  match
    List.find
      ~f:(fun tool_group -> String.equal name (Workspace.Tool_group.name tool_group))
      workspace.tool_groups
  with
  | Some group -> group
  | None ->
    User_error.raise
      [ Pp.textf "Tool group %S is not declared in the workspace." name ]
      ~hints:[ Pp.text "Add a (tool_group ...) stanza to dune-workspace." ]
;;

let local_package_of_group (tool_group : Workspace.Tool_group.t) =
  let name =
    Package_name.of_string (Workspace.Tool_group.name tool_group ^ "_tool_group")
  in
  let version = Dune_pkg.Lock_dir.Pkg_info.default_version in
  (* Version of the root*)
  let dependencies =
    Dune_pkg.Dependency_formula.of_dependencies (List.map ~f:snd tool_group.tools)
  in
  (* No way to specify them in the stanza yet *)
  let conflicts = [] in
  let conflict_class = [] in
  let depopts = [] in
  let pins = Package_name.Map.empty in
  let loc = tool_group.loc in
  let command_source = Dune_pkg.Local_package.Opam_file { build = []; install = [] } in
  { Dune_pkg.Local_package.name
  ; version
  ; dependencies
  ; conflicts
  ; conflict_class
  ; depopts
  ; pins
  ; loc
  ; command_source
  }
;;

let lock name ~portable_lock_dir =
  let open Fiber.O in
  let* workspace, group =
    Memo.run
      (let open Memo.O in
       let+ workspace = Workspace.workspace () in
       workspace, find_group workspace name)
  in
  match group.lock_dir with
  | Inherit _ ->
    User_error.raise
      ~loc:group.loc
      [ Pp.text "Locking a tool group that inherits a context is not supported yet" ]
  | Lock_dir lockdir ->
    let* solver_env_from_current_system =
      Pkg.Pkg_common.poll_solver_env_from_current_system () >>| Option.some
    in
    let local_package = local_package_of_group group in
    let lock_dir_path = Path.external_ (Dune_rules.Lock_dir.tool_external_lock_dir group) in
    Pkg.Lock.solve
      workspace
      ~local_packages:(Package_name.Map.singleton local_package.name local_package)
      ~project_pins:Dune_pkg.Pin.DB.empty
      ~solver_env_from_current_system
      ~version_preference:None
      ~lock_dirs:[lock_dir_path, Some lockdir ]
      ~print_perf_stats:false
      ~portable_lock_dir
;;

let term =
  let+ builder = Common.Builder.term
  and+ tools_arg =
    Arg.(
      required
      & pos 0 (some string) None
      & info [] ~docv:"TOOL_GROUP" ~doc:(Some "Name of the tool group to lock"))
  in
  let builder = Common.Builder.forbid_builds builder in
  let common, config = Common.init builder in
  Scheduler_setup.go_with_rpc_server ~common ~config (fun () ->
    let portable_lock_dir =
      match Config.get Dune_rules.Compile_time.portable_lock_dir with
      | `Enabled -> true
      | `Disabled -> false
    in
    lock ~portable_lock_dir tools_arg)
;;

let info =
  let doc = "Lock a tool group declared in dune-workspace" in
  Cmd.info "lock" ~doc
;;

let command = Cmd.v info term
