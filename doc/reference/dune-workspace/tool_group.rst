tool_group
==========

.. warning::

   This stanza is unreleased and a work in progress. It is parsed and validated,
   but tools declared with it are not yet locked, built, or runnable. It may
   change without notice.

Declares developer tools that are managed by Dune's package management but are
not dependencies of the project, such as ``ocamlformat`` or
``ocaml-lsp-server``.

To enable the stanza, add ``(using unreleased 0.1)`` :doc:`extension
</reference/dune-project/using>` to your ``dune-workspace`` file.

.. describe:: (tool_group ...)

   .. describe:: (name <string>)

      Optional. Two groups may not share a name.

   .. describe:: (tools <dep-specification> ...)

      The packages providing the tools, in the
      :token:`~pkg-dep:dep_specification` format used by ``depends``. At least
      one is required. A package declared in a group with ``lock_dir`` may
      not be declared in any other group. Otherwise a package may be declared
      at most once per inherited context.

   Exactly one of either ``lock_dir`` or ``inherit`` is required.

   .. describe:: (lock_dir ...)

      Solve the tools in isolation. Accepts the fields of the :doc:`lock_dir`
      stanza.

   .. describe:: (inherit ...)

      Build the tools as an extension of the package environment of an existing
      context.

      .. describe:: (context <name>)

         Required. The :doc:`context` whose lock directory the tools are
         solved on top of. It must be a default context, not an opam one.

      .. describe:: (shared_packages <name> ...)

         Optional. The tools must re-use these packages from the inherited
         context, along with everything these packages depend on. At least one
         package is required when the field is present. When the field is
         omitted, Dune re-uses the context's packages where possible.

Example:

.. code:: dune

   (tool_group
    (name format)
    (tools ocamlformat ocp-indent)
    (lock_dir))

   (tool_group
    (tools (ocaml-lsp-server (>= 1.27.0)) utop)
    (inherit (context default)))
