Locking a tool group that inherits a context.

  $ mkrepo
  $ mkpkg bar <<EOF
  > EOF
  $ mkpkg baz <<EOF
  > EOF
  $ mkpkg foo <<EOF
  > depends: [ "bar" "baz" ]
  > EOF

The project depends on bar, so the default context's lock dir provides it:

  $ cat > dune-project <<EOF
  > (lang dune 3.20)
  > (package
  >  (name x)
  >  (allow_empty)
  >  (depends bar))
  > EOF
  $ cat > dune-workspace <<EOF
  > (lang dune 3.25)
  > (using unreleased 0.1)
  > (repository
  >  (name mock)
  >  (url "file://$(pwd)/mock-opam-repository"))
  > (lock_dir
  >  (repositories mock))
  > (tool_group
  >  (tools foo)
  >  (inherit (context default)))
  > EOF

Locking the group before the context has a lock dir solves the context on
demand in the build directory, the same as building would, and locks the group
against that solution:

  $ dune tools lock foo
  Solution for _build/.tools.locks/foo
  
  Dependencies common to all supported platforms:
  - baz.0.0.1
  - foo.0.0.1

  $ dune pkg lock
  Solution for dune.lock
  
  Dependencies common to all supported platforms:
  - bar.0.0.1

The group reuses bar from the context and only locks what it adds:

  $ dune tools lock foo
  Solution for _build/.tools.locks/foo
  
  Dependencies common to all supported platforms:
  - baz.0.0.1
  - foo.0.0.1
  $ ls _build/.tools.locks/foo
  baz.0.0.1.pkg
  foo.0.0.1.pkg
  lock.dune

A shared package is fixed at the version the context locked. A tool that
needs a different version cannot be solved, even though the repository has it:

  $ mkpkg bar 0.0.2 <<EOF
  > EOF
  $ mkpkg qux <<EOF
  > depends: [ "bar" {= "0.0.2"} ]
  > EOF
  $ cat >> dune-workspace <<EOF
  > (tool_group
  >  (tools qux)
  >  (inherit (context default) (shared_packages bar)))
  > EOF
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
