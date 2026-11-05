Two tool groups each install a binary with the same name. Requesting that
name reports the conflict rather than silently picking one of them.

  $ mkrepo
  $ mkpkg toola 1.0.0 <<EOF
  > install: [
  >   [ "mkdir" "-p" "%{bin}%" ]
  >   [ "sh" "-c" "printf '#!/bin/sh\necho clash from toola\n' > %{bin}%/clash" ]
  >   [ "chmod" "+x" "%{bin}%/clash" ]
  > ]
  > EOF
  $ mkpkg toolb 1.0.0 <<EOF
  > install: [
  >   [ "mkdir" "-p" "%{bin}%" ]
  >   [ "sh" "-c" "printf '#!/bin/sh\necho clash from toolb\n' > %{bin}%/clash" ]
  >   [ "chmod" "+x" "%{bin}%/clash" ]
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
  >  (tools toola)
  >  (lock_dir (repositories mock)))
  > (tool_group
  >  (tools toolb)
  >  (lock_dir (repositories mock)))
  > EOF

  $ dune tools lock toola
  Solution for _build/.tools.locks/toola
  
  Dependencies common to all supported platforms:
  - toola.1.0.0

  $ dune tools lock toolb
  Solution for _build/.tools.locks/toolb
  
  Dependencies common to all supported platforms:
  - toolb.1.0.0


Both groups are locked and both provide a binary named "clash". Requesting
that name reports the conflict instead of picking one:

  $ dune exec clash
  Error: Program 'clash' not found!
  [1]
