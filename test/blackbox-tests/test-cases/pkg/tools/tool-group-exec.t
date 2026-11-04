How "dune exec" resolves the binaries of tool groups. A tool is found after
the project's own executables and before programs on PATH. Only locked
groups are searched.

  $ mkrepo
  $ mkpkg foo <<EOF
  > install: [
  >   [ "mkdir" "-p" "%{bin}%" ]
  >   [ "sh" "-c" "printf '#!/bin/sh\necho tool foo\n' > %{bin}%/foo" ]
  >   [ "chmod" "+x" "%{bin}%/foo" ]
  > ]
  > EOF

  $ cat > dune-project <<EOF
  > (lang dune 3.25)
  > (package (name proj))
  > EOF
  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (repository
  >  (name mock)
  >  (url "file://$(pwd)/mock-opam-repository"))
  > (tool_group
  >  (tools foo)
  >  (lock_dir (repositories mock)))
  > (tool_group
  >  (tools bar)
  >  (lock_dir (repositories mock)))
  > EOF

The group of "foo" is not locked yet. Its binaries cannot be searched:

  $ dune exec foo
  Error: Program 'foo' not found!
  [1]

Once locked, the tool is built and run:

  $ dune tools lock foo
  Solution for _build/.tools.locks/foo
  
  Dependencies common to all supported platforms:
  - foo.0.0.1

  $ dune exec foo
  tool foo

A program of the same name on PATH loses to the tool:

  $ mkdir path-bin
  $ printf '#!/bin/sh\necho foo from PATH\n' > path-bin/foo
  $ chmod +x path-bin/foo
  $ PATH="$PWD/path-bin:$PATH" dune exec foo
  tool foo

The group of "bar" is still not locked, so "bar" is not found. The error
points at locking the group:

  $ dune exec bar
  Error: Program 'bar' not found!
  [1]

An executable of the project wins over the tool:

  $ cat > dune <<EOF
  > (executable
  >  (name foo)
  >  (public_name foo))
  > EOF
  $ cat > foo.ml <<EOF
  > let () = print_endline "project foo"
  > EOF
  $ dune exec foo
  project foo
