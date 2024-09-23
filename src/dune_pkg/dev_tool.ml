open! Import

type t =
  | Ocamlformat
  | Odoc

let all = [ Ocamlformat; Odoc ]

let equal a b =
  match a, b with
  | Ocamlformat, Ocamlformat -> true
  | Odoc, Odoc -> true
  | _ -> false
;;

let package_name = function
  | Ocamlformat -> Package_name.of_string "ocamlformat"
  | Odoc -> Package_name.of_string "odoc"
;;

let of_package_name package_name =
  match Package_name.to_string package_name with
  | "ocamlformat" -> Ocamlformat
  | "odoc" -> Odoc
  | other -> User_error.raise [ Pp.textf "No such dev tool: %s" other ]
;;

let exe_name = function
  | Ocamlformat -> "ocamlformat"
  | Odoc -> "odoc"
;;

let exe_path_components_within_package t =
  match t with
  | Ocamlformat -> [ "bin"; exe_name t ]
  | Odoc -> [ "bin"; exe_name t ]
;;

let needs_to_build_with_same_compiler_as_project = function
  | Ocamlformat -> false
  | Odoc -> true
;;
