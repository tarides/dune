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

(* Helper for a package group that reused shared pkg from its parent context *)
let local_package_of_shared_pkg ~platform (pkg : Dune_pkg.Lock_dir.Pkg.t) =
  let dependencies =
    Dune_pkg.Lock_dir.Conditional_choice.choose_for_platform pkg.depends ~platform
    |> Option.value ~default:[]
    |> List.map ~f:(fun { Dune_pkg.Lock_dir.Dependency.name; loc = _ } ->
      { Dune_lang.Package_dependency.name; constraint_ = None })
    |> Dune_pkg.Dependency_formula.of_dependencies
  in
  { Dune_pkg.Local_package.name = pkg.info.name
  ; version = pkg.info.version
  ; dependencies
  ; conflicts = []
  ; conflict_class = []
  ; depopts = []
  ; pins = Package_name.Map.empty
  ; loc = Loc.none
  ; command_source = Dune_pkg.Local_package.Opam_file { build = []; install = [] }
  }
;;

let resolved_package_of_shared_pkg ~platform (pkg : Dune_pkg.Lock_dir.Pkg.t) =
  let local_package = local_package_of_shared_pkg ~platform pkg in
  let opam_file =
    Dune_pkg.Local_package.for_solver local_package
    |> Dune_pkg.Local_package.For_solver.to_opam_file
  in
  let opam_package =
    OpamPackage.create
      (Dune_pkg.Package_name.to_opam_package_name pkg.info.name)
      (Dune_pkg.Package_version.to_opam_package_version pkg.info.version)
  in
  Dune_pkg.Resolved_package.local_package
    ~command_source:local_package.command_source
    (Loc.none, opam_file)
    opam_package
;;

let lock name ~portable_lock_dir =
  let open Fiber.O in
  let* workspace, lock_dir_path, lockdir, local_packages, provided_packages =
    Memo.run
      (let open Memo.O in
       let* workspace = Workspace.workspace () in
       let group = find_group workspace name in
       let lock_dir_path =
         Path.external_ (Dune_rules.Lock_dir.tool_external_lock_dir group)
       in
       let root = local_package_of_group group in
       match group.lock_dir with
       | Inherit { context = _, ctx; shared_packages = _ } ->
         let* parent = Dune_rules.Lock_dir.get ctx
         and* platform = Dune_rules.Lock_dir.Sys_vars.solver_env
         and* parent_path = Dune_rules.Lock_dir.get_path ctx in
         let parent =
           match parent with
           | Ok parent -> parent
           | Error _ ->
             User_error.raise
               ~loc:group.loc
               [ Pp.textf
                   "Context %S has no lock directory to inherit from."
                   (Context_name.to_string ctx)
               ]
               ~hints:
                 [ Pp.concat
                     ~sep:Pp.space
                     [ Pp.text "Run"; User_message.command "dune pkg lock" ]
                 ]
         in
         let parent_path =
           match parent_path with
           | Some path -> path
           | None ->
             Code_error.raise
               "inherited context has no lock dir path"
               [ "context", Context_name.to_dyn ctx ]
         in
         let shared = Dune_pkg.Lock_dir.packages_on_platform parent ~platform in
         let local_packages = Package_name.Map.singleton root.name root in
         let provided_package =
           Package_name.Map.map shared ~f:(resolved_package_of_shared_pkg ~platform)
         in
         let lock_dir = Workspace.find_lock_dir workspace parent_path in
         Memo.return (workspace, lock_dir_path, lock_dir, local_packages, provided_package)
       | Lock_dir lockdir ->
         Memo.return
           ( workspace
           , lock_dir_path
           , Some lockdir
           , Package_name.Map.singleton root.name root
           , Package_name.Map.empty ))
  in
  let* solver_env_from_current_system =
    Pkg.Pkg_common.poll_solver_env_from_current_system () >>| Option.some
  in
  Pkg.Lock.solve
    workspace
    ~local_packages
    ~project_pins:Dune_pkg.Pin.DB.empty
    ~solver_env_from_current_system
    ~version_preference:None
    ~lock_dirs:[ lock_dir_path, lockdir, provided_packages ]
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
