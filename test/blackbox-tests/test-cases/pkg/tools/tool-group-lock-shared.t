An inheriting tool group reuses the packages of its context where it can.
Packages it must lock itself are those whose version, or whose dependency
closure, differs from the context's.

  $ mkrepo
  $ mkpkg bar <<EOF
  > EOF
  $ mkpkg bar 0.0.2 <<EOF
  > EOF
  $ mkpkg qax <<EOF
  > depends: [ "bar" ]
  > EOF
  $ mkpkg qux <<EOF
  > depends: [ "bar" {= "0.0.2"} ]
  > EOF
  $ mkpkg quux <<EOF
  > depends: [ "qax" ]
  > EOF

The project locks bar.0.0.1 and qax on top of it:

  $ cat > dune-project <<EOF
  > (lang dune 3.20)
  > (package
  >  (name x)
  >  (allow_empty)
  >  (depends (bar (= 0.0.1)) qax))
  > EOF
  $ workspace () {
  >   cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (repository
  >  (name mock)
  >  (url "file://$(pwd)/mock-opam-repository"))
  > (lock_dir
  >  (repositories mock))
  > $1
  > EOF
  > }
  $ workspace ""
  $ dune pkg lock
  Solution for dune.lock
  
  Dependencies common to all supported platforms:
  - bar.0.0.1
  - qax.0.0.1


A tool whose dependency closure is identical to the context's locks only
itself. qax and bar are reused, even though bar.0.0.2 is available:

  $ workspace "(tool_group
  >  (tools quux)
  >  (inherit (context default)))"
  $ dune tools lock quux
  Solution for _build/.tools.locks/quux
  
  Dependencies common to all supported platforms:
  - quux.0.0.1

  $ ls _build/.tools.locks/quux
  lock.dune
  quux.0.0.1.pkg

A tool that needs a different version of a shared package gets its own
copy, since nothing requires the context's version:

  $ workspace "(tool_group
  >  (tools qux)
  >  (inherit (context default)))"
  $ dune tools lock qux
  Solution for _build/.tools.locks/qux
  
  Dependencies common to all supported platforms:
  - bar.0.0.2
  - qux.0.0.1

  $ ls _build/.tools.locks/qux
  bar.0.0.2.pkg
  lock.dune
  qux.0.0.1.pkg

A package that keeps the context's version but depends on a package the
group changed is not shared either. The group locks and builds it itself:

  $ workspace "(tool_group
  >  (name mixed)
  >  (tools qux qax)
  >  (inherit (context default)))"
  $ dune tools lock mixed
  Solution for _build/.tools.locks/mixed
  
  Dependencies common to all supported platforms:
  - bar.0.0.2
  - qax.0.0.1
  - qux.0.0.1

  $ ls _build/.tools.locks/mixed
  bar.0.0.2.pkg
  lock.dune
  qax.0.0.1.pkg
  qux.0.0.1.pkg

Listing a package in shared_packages makes reuse a requirement: the solve
fails rather than lock a different version:

  $ workspace "(tool_group
  >  (tools qux)
  >  (inherit (context default) (shared_packages bar)))"
  $ dune tools lock qux
  Error:
  Unable to solve dependencies while generating lock directory:
  $TESTCASE_ROOT/_build/.tools.locks/qux
  
  The dependency solver failed to find a solution for the requested platforms:
  - arch = x86_64; os = linux
  - arch = arm64; os = linux
  - arch = x86_64; os = macos
  - arch = arm64; os = macos
  ...with this error:
  Couldn't solve the package dependency formula.
  Selected candidates: qux.0.0.1 qux_tool_group.dev
  - bar -> (problem)
      qux 0.0.1 requires = 0.0.2
      Rejected candidates:
        bar.0.0.1: Incompatible with restriction: = 0.0.2
  [1]


A package named in shared_packages must be in the context's lock dir:

  $ workspace "(tool_group
  >  (tools quux)
  >  (inherit (context default) (shared_packages nosuch)))"
  $ dune tools lock quux
  File "dune-workspace", lines 8-10, characters 0-80:
   8 | (tool_group
   9 |  (tools quux)
  10 |  (inherit (context default) (shared_packages nosuch)))
  Error: The following shared packages are not in the lock directory of context
  "default": nosuch
  [1]
