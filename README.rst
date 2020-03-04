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


``git archive-all`` works similar to ``git archive``, but will also include
files from submodules into the archive. This is not the only implementation of
this particular feature, but it is the one that mimics ``git archive`` best.
It uses the same command line arguments, and in the absense of submodules, it
will behave identically. Basically, you can use it for all
archiving purposes and need not to think about the technicalities of
submodules.

Installation
------------

Just place the ``git-archive-all`` bash script in a location that is in your
``$PATH``. If you have root privileges, ``/usr/local/bin`` is a reasonable
choice. Otherwise, you may be able to use ``$HOME/.local/bin`` to the same
effect, or you can call the script directly without installing it first, albeit
less conveniently.

Alternatives
------------

If this script does not satisfy your needs, you may be interested in one of the
following alternatives instead:

* https://github.com/meitar/git-archive-all.sh

  Another bash script that can put submodules into separate archives.

* https://github.com/Kentzo/git-archive-all

  A Python implementation that can handle arbitrary filenames with weird
  character sets, including newlines.

