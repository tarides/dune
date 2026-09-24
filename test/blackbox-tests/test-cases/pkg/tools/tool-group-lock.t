Locking a tool group with `dune tools lock`.

  $ mkrepo
  $ mkpkg bar <<EOF
  > EOF
  $ mkpkg foo <<EOF
  > depends: [ "bar" ]
  > EOF

An isolated group declaring one tool is solved against the group's own
repositories and written under _build:

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
  $ ls _build/.tools.locks/foo
  bar.0.0.1.pkg
  foo.0.0.1.pkg
  lock.dune
  $ cat _build/.tools.locks/foo/foo.0.0.1.pkg
  (version 0.0.1)
  
  (depends
   (all_platforms (bar)))

Only declared groups can be locked:

  $ dune tools lock nosuch
  Error: Tool group "nosuch" is not declared in the workspace.
  Hint: Add a (tool_group ...) stanza to dune-workspace.
  [1]
