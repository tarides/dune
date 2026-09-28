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

Locking again replaces the previous lock dir:

  $ dune tools lock foo
  Solution for _build/.tools.locks/foo
  
  Dependencies common to all supported platforms:
  - bar.0.0.1
  - foo.0.0.1
  Internal error! Please report to https://github.com/ocaml/dune/issues,
  providing the file _build/trace.csexp, if possible. This includes build
  commands, message logs, and file paths.
  Description:
    ("Unexpected external path",
     { dir =
         External
           "$TESTCASE_ROOT/_build/.tools.locks/.foo"
     ; components = [ ".tools.locks"; ".foo" ]
     })
  Raised at Stdune__Exn.protectx in file "otherlibs/stdune/src/exn.ml", line
    16, characters 4-11
  Called from Stdlib__List.iter in file "list.ml", line 114, characters 12-15
  Called from Fiber__Scheduler.exec in file "src/fiber/src/scheduler.ml", line
    101, characters 11-22
  
  I must not crash.  Uncertainty is the mind-killer. Exceptions are the
  little-death that brings total obliteration.  I will fully express my cases. 
  Execution will pass over me and through me.  And when it has gone past, I
  will unwind the stack along its path.  Where the cases are handled there will
  be nothing.  Only I will remain.
  [1]

Only declared groups can be locked:

  $ dune tools lock nosuch
  Error: Tool group "nosuch" is not declared in the workspace.
  Hint: Add a (tool_group ...) stanza to dune-workspace.
  [1]
