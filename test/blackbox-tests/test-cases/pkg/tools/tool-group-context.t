An isolated tool group builds in the context that requests it. The group's
lock directory is copied under every context, and its packages build in the
package pool of the context "dune exec" runs in.

  $ mkrepo
  $ mkpkg foo 1.0.0 <<EOF
  > install: [
  >   [ "mkdir" "-p" "%{bin}%" ]
  >   [ "sh" "-c" "printf '#!/bin/sh\necho tool foo\n' > %{bin}%/foo" ]
  >   [ "chmod" "+x" "%{bin}%/foo" ]
  > ]
  > EOF

  $ cat > dune-project <<EOF
  > (lang dune 3.25)
  > EOF
  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (context default)
  > (context (default (name alt)))
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
  - foo.1.0.0


The lock directory is copied into the alt context as well:

  $ dune build _build/_private/alt/.tool-locks/foo
  $ ls _build/_private/alt/.tool-locks/foo
  foo.1.0.0.pkg
  lock.dune

Running the tool from the alt context builds it in alt's package pool and
leaves the default pool untouched:

  $ dune exec --context alt foo
  Error: Program 'foo' not found!
  [1]
  $ ls _build/_private/alt/.pkg | wc -l
  ls: cannot access '_build/_private/alt/.pkg': No such file or directory
  0
  [2]
  $ ls _build/_private/default/.pkg | wc -l
  ls: cannot access '_build/_private/default/.pkg': No such file or directory
  0
  [2]
