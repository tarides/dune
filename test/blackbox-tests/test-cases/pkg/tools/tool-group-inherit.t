The (inherit ...) field of a tool group, an alternative to (lock_dir ...). It
names a context and optionally restricts which of its packages are shared.

A group inheriting from the default context:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (tool_group
  >  (tools ocaml-lsp-server)
  >  (inherit (context default)))
  > EOF
  $ dune build

A group inheriting from a named context and sharing only some packages:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (context (default (name other)))
  > (tool_group
  >  (tools ocaml-lsp-server)
  >  (inherit (context other) (shared_packages ocaml)))
  > EOF
  $ dune build

An empty shared_packages field is rejected, since sharing nothing is what a
lock_dir group does:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (tool_group
  >  (tools ocaml-lsp-server)
  >  (inherit (context default) (shared_packages)))
  > EOF
  $ dune build
  File "dune-workspace", line 5, characters 28-45:
  5 |  (inherit (context default) (shared_packages)))
                                  ^^^^^^^^^^^^^^^^^
  Error: No packages were specified to share.
  Hint: Name at least one package here, or remove the field to reuse the
  context's packages where possible.
  [1]

The inherited context must exist:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (tool_group
  >  (name dev)
  >  (tools ocaml-lsp-server)
  >  (inherit (context nosuch)))
  > EOF
  $ dune build
  File "dune-workspace", line 6, characters 19-25:
  6 |  (inherit (context nosuch)))
                         ^^^^^^
  Error: Context "nosuch" is not defined.
  [1]

An opam context has no lock directory to inherit:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (context (opam (switch foo)))
  > (tool_group
  >  (tools ocaml-lsp-server)
  >  (inherit (context foo)))
  > EOF
  $ dune build
  File "dune-workspace", line 6, characters 19-22:
  6 |  (inherit (context foo)))
                         ^^^
  Error: Context "foo" is an opam context and inheriting from an opam context
  is not supported yet.
  [1]

inherit and lock_dir are mutually exclusive:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (tool_group
  >  (name dev)
  >  (tools ocaml-lsp-server)
  >  (inherit (context default))
  >  (lock_dir (constraints (ocaml (= 5.3.0)))))
  > EOF
  $ dune build
  File "dune-workspace", lines 3-7, characters 0-123:
  3 | (tool_group
  4 |  (name dev)
  5 |  (tools ocaml-lsp-server)
  6 |  (inherit (context default))
  7 |  (lock_dir (constraints (ocaml (= 5.3.0)))))
  Error: fields "lock_dir" and "inherit" are mutually exclusive.
  [1]

shared_packages only exists under inherit, not under lock_dir:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (tool_group
  >  (tools ocaml-lsp-server)
  >  (lock_dir (shared_packages ocaml)))
  > EOF
  $ dune build
  File "dune-workspace", line 5, characters 12-27:
  5 |  (lock_dir (shared_packages ocaml)))
                  ^^^^^^^^^^^^^^^
  Error: Unknown field "shared_packages"
  [1]

The same tool may be declared once per context. Each group still needs its
own name, so all but one of them must be named explicitly:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (context default)
  > (context (default (name other)))
  > (tool_group
  >  (tools ocaml-lsp-server)
  >  (inherit (context default)))
  > (tool_group
  >  (name lsp-other)
  >  (tools ocaml-lsp-server)
  >  (inherit (context other)))
  > EOF
  $ dune build

A group without a name is named after its tool, so two anonymous groups
declaring the same tool collide even in different contexts:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (context default)
  > (context (default (name other)))
  > (tool_group
  >  (tools ocaml-lsp-server)
  >  (inherit (context default)))
  > (tool_group
  >  (tools ocaml-lsp-server)
  >  (inherit (context other)))
  > EOF
  $ dune build
  File "dune-workspace", lines 8-10, characters 0-65:
   8 | (tool_group
   9 |  (tools ocaml-lsp-server)
  10 |  (inherit (context other)))
  Error: Tool group "ocaml-lsp-server" is declared multiple times:
  - dune-workspace:5
  - dune-workspace:8
  Hint: A group without a (name ...) field is named after its tool. Give one of
  these groups an explicit name.
  [1]

But not in both a group without inherit and a group that inherits, since the
former is usable from every context:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (tool_group
  >  (name lsp-isolated)
  >  (tools ocaml-lsp-server)
  >  (lock_dir))
  > (tool_group
  >  (tools ocaml-lsp-server)
  >  (inherit (context default)))
  > EOF
  $ dune build
  File "dune-workspace", line 8, characters 8-24:
  8 |  (tools ocaml-lsp-server)
              ^^^^^^^^^^^^^^^^
  Error: Tool "ocaml-lsp-server" is declared multiple times for context
  "default":
  - dune-workspace:5
  - dune-workspace:8
  Hint: A tool declared in a lock_dir group may not be declared again.
  Otherwise a tool may be declared once per inherited context.
  [1]

Nor twice for the same context:

  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (tool_group
  >  (tools ocaml-lsp-server)
  >  (inherit (context default)))
  > (tool_group
  >  (name dev)
  >  (tools ocaml-lsp-server utop)
  >  (inherit (context default)))
  > EOF
  $ dune build
  File "dune-workspace", line 8, characters 8-24:
  8 |  (tools ocaml-lsp-server utop)
              ^^^^^^^^^^^^^^^^
  Error: Tool "ocaml-lsp-server" is declared multiple times for context
  "default":
  - dune-workspace:4
  - dune-workspace:8
  Hint: A tool declared in a lock_dir group may not be declared again.
  Otherwise a tool may be declared once per inherited context.
  [1]
