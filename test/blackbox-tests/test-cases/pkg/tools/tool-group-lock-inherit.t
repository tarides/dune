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

Locking the group before the context it inherits from fails:

  $ dune tools lock foo

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
