A tool package that provides several binaries, none of which is named after
the package. Every binary the package installs can be run by name.

  $ mkrepo
  $ mkpkg multibin 1.0.0 <<EOF
  > install: [
  >   [ "mkdir" "-p" "%{bin}%" ]
  >   [ "sh" "-c" "printf '#!/bin/sh\necho alpha\n' > %{bin}%/alpha" ]
  >   [ "chmod" "+x" "%{bin}%/alpha" ]
  >   [ "sh" "-c" "printf '#!/bin/sh\necho beta\n' > %{bin}%/beta" ]
  >   [ "chmod" "+x" "%{bin}%/beta" ]
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
  >  (tools multibin)
  >  (lock_dir (repositories mock)))
  > EOF

  $ dune tools lock multibin
  Solution for _build/.tools.locks/multibin
  
  Dependencies common to all supported platforms:
  - multibin.1.0.0


The binaries the locked tool provides can be run by name:

  $ dune exec alpha
  Error: Program 'alpha' not found!
  [1]
  $ dune exec beta
  Error: Program 'beta' not found!
  [1]

The package name is not a binary name. Running it is an ordinary not-found:

  $ dune exec multibin
  Error: Program 'multibin' not found!
  [1]
