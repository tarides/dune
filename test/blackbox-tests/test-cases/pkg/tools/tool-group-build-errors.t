Error cases when building a locked tool group. Each scenario uses its own
group so that they do not interfere.

  $ mkrepo
  $ mkpkg buildfail 1.0.0 <<EOF
  > build: [ "sh" "-c" "echo something went wrong; exit 1" ]
  > EOF
  $ mkpkg nobin 1.0.0 <<EOF
  > EOF
  $ mkpkg badbar 1.0.0 <<EOF
  > build: [ "sh" "-c" "echo dependency broke; exit 1" ]
  > EOF
  $ mkpkg depfail 1.0.0 <<EOF
  > depends: [ "badbar" ]
  > EOF

A tarball for the badcheck tool, served by the fake curl, whose opam file
declares a wrong checksum:

  $ mkdir badcheck-src
  $ printf '#!/bin/sh\necho badcheck\n' > badcheck-src/badcheck.sh
  $ tar cf badcheck.tar badcheck-src
  $ rm -rf badcheck-src
  $ echo badcheck.tar >> fake-curls
  $ PORT=1
  $ mkpkg badcheck 1.0.0 <<EOF
  > install: [ "sh" "-c" "mkdir -p %{bin}% && cp badcheck.sh %{bin}%/badcheck" ]
  > url {
  >  src: "http://0.0.0.0:$PORT"
  >  checksum: [ "md5=00000000000000000000000000000000" ]
  > }
  > EOF

  $ mkpkg tampered 1.0.0 <<EOF
  > install: [ "sh" "-c" "mkdir -p %{bin}% && touch %{bin}%/tampered" ]
  > EOF
  $ mkpkg corrupt 1.0.0 <<EOF
  > install: [ "sh" "-c" "mkdir -p %{bin}% && touch %{bin}%/corrupt" ]
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
  > (tool_group (tools buildfail) (lock_dir (repositories mock)))
  > (tool_group (tools nobin) (lock_dir (repositories mock)))
  > (tool_group (tools depfail) (lock_dir (repositories mock)))
  > (tool_group (tools badcheck) (lock_dir (repositories mock)))
  > (tool_group (tools tampered) (lock_dir (repositories mock)))
  > (tool_group (tools corrupt) (lock_dir (repositories mock)))
  > EOF

The build command of the tool's package fails:

  $ dune tools lock buildfail
  Solution for _build/.tools.locks/buildfail
  
  Dependencies common to all supported platforms:
  - buildfail.1.0.0

  $ dune exec buildfail
  Error: Program 'buildfail' not found!
  [1]

The tool's package builds but installs no binary at all:

  $ dune tools lock nobin
  Solution for _build/.tools.locks/nobin
  
  Dependencies common to all supported platforms:
  - nobin.1.0.0

  $ dune exec nobin
  Error: Program 'nobin' not found!
  [1]

The build command of one of the tool's dependencies fails:

  $ dune tools lock depfail
  Solution for _build/.tools.locks/depfail
  
  Dependencies common to all supported platforms:
  - badbar.1.0.0
  - depfail.1.0.0

  $ dune exec depfail
  Error: Program 'depfail' not found!
  [1]

The fetched source of the tool does not match the checksum recorded in the
lock directory:

  $ dune tools lock badcheck
  Solution for _build/.tools.locks/badcheck
  
  Dependencies common to all supported platforms:
  - badcheck.1.0.0

  $ actual=$(md5sum badcheck.tar | cut -f1 -d' ')
  $ dune exec badcheck 2>&1 | sed "s/$actual/ACTUAL/g"
  Error: Program 'badcheck' not found!
  [1]

The lockfile of the tool's package was deleted from the lock directory:

  $ dune tools lock tampered
  Solution for _build/.tools.locks/tampered
  
  Dependencies common to all supported platforms:
  - tampered.1.0.0

  $ rm _build/.tools.locks/tampered/tampered.1.0.0.pkg
  $ dune exec tampered
  Error: Program 'tampered' not found!
  [1]

The lock.dune of the group's lock directory is corrupted:

  $ dune tools lock corrupt
  Solution for _build/.tools.locks/corrupt
  
  Dependencies common to all supported platforms:
  - corrupt.1.0.0

  $ echo garbage > _build/.tools.locks/corrupt/lock.dune
  $ dune exec corrupt
  Error: Program 'corrupt' not found!
  [1]
