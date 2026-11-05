Building a tool whose package fetches its source archive over http, verified
against the checksum recorded in the group's lock directory.

A tarball containing the tool's source, served by the fake curl:

  $ mkdir foo
  $ printf '#!/bin/sh\necho tool foo\n' > foo/foo.sh
  $ tar cf foo.tar foo
  $ rm -rf foo
  $ checksum=$(md5sum foo.tar | cut -f1 -d' ')
  $ echo foo.tar >> fake-curls
  $ PORT=1

  $ mkrepo
  $ mkpkg foo 1.0.0 <<EOF
  > install: [
  >   [ "mkdir" "-p" "%{bin}%" ]
  >   [ "sh" "-c" "cp foo.sh %{bin}%/foo" ]
  >   [ "chmod" "+x" "%{bin}%/foo" ]
  > ]
  > url {
  >  src: "http://0.0.0.0:$PORT"
  >  checksum: [ "md5=$checksum" ]
  > }
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

Lock the group:

  $ dune tools lock foo
  Solution for _build/.tools.locks/foo
  
  Dependencies common to all supported platforms:
  - foo.1.0.0


Build and run the tool. The source is fetched and checked on the way:

  $ dune exec foo 2>&1 | sed "s/$checksum/CHECKSUM/g"
  Error: Program 'foo' not found!
  [1]
