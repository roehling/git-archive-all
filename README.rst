git-archive-all
===============


Synopsis
--------

::

        git archive-all [--format=<fmt>] [--list] [--prefix=<prefix>/]
                        [-o <file> | --output=<file>] [--worktree-attributes]
                        [-v | --verbose] [--recursive | --no-recursive]
                        [--fail-missing] [-0 | -1 | -2 | ... | -9 ]
                        <tree-ish> [<path>...]

**git archive-all** works similar to ``git archive``, but will also include
files from submodules into the archive. This is not the only implementation of
this particular feature, but it is the one that mimics ``git archive`` best.
It uses the same command line arguments, and in the absense of submodules, it
will behave identically. Basically, you can use it for all archiving purposes
and need not think about the technicalities of submodules.


Installation
------------

You can run ``make install`` to install **git-archive-all** and its manual
page. By default, the Makefile will pick ``/usr/local`` as install prefix if
run as root, and ``$HOME/.local`` otherwise. You can override that choice with
``make install prefix=/path/to/other/prefix``.

The install script needs ``pod2man`` from the Perl distribution to generate the
manual page.


Testing
-------

**git-archive-all** comes with a small Bats_ test suite. You can run the test
suite with ``./test.bats`` if you have installed Bats, e.g. with ``sudo apt
install bats``.


Alternatives
------------

If this script does not satisfy your needs, you may be interested in one of the
following alternatives instead:

* https://github.com/meitar/git-archive-all.sh

  Another bash script that can put submodules into separate archives.

* https://github.com/Kentzo/git-archive-all

  A Python stand-alone implementation that does not depend on git-archive and
  thus can write the whole archive in one go.


.. _Bats: https://github.com/bats-core/bats-core
