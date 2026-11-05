Building and running the tool of an isolated group. The project does not use
package management; the group's dependencies build in the context's package
pool from the group's own lock directory.

  $ mkrepo
  $ mkpkg bar <<EOF
  > EOF
  $ mkpkg foo <<EOF
  > depends: [ "bar" ]
  > install: [
  >   [ "mkdir" "-p" "%{bin}%" ]
  >   [ "sh" "-c" "printf '#!/bin/sh\necho hello from foo\n' > %{bin}%/foo" ]
  >   [ "chmod" "+x" "%{bin}%/foo" ]
  > ]
  > EOF

  $ cat > dune-project <<EOF
  > (lang dune 3.25)
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
  > EOF
  $ dune tools lock foo
  Solution for _build/.tools.locks/foo
  
  Dependencies common to all supported platforms:
  - bar.0.0.1
  - foo.0.0.1

The group's lock dir is copied into the context:

  $ dune build _build/_private/default/.tool-locks/foo
  $ ls _build/_private/default/.tool-locks/foo
  bar.0.0.1.pkg
  foo.0.0.1.pkg
  lock.dune

Run the tool. It is built on demand together with its dependency:

  $ dune exec foo
  Error: Program 'foo' not found!
  [1]

Both packages were built in the default context's package pool, and no
project lock directory was created:

  $ ls _build/_private/default/.pkg | wc -l
  ls: cannot access '_build/_private/default/.pkg': No such file or directory
  0
  [2]
  $ ls dune.lock
  ls: cannot access 'dune.lock': No such file or directory
  [2]
