#
# GIT-ARCHIVE-ALL
#
# Copyright (c) 2019 Timo Röhling
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
ifneq ($(if $(DESTDIR),0,$(shell id -u)),0)
# If the current user is not root and DESTDIR is not set, install to user home
prefix ?= $(HOME)/.local
else
prefix ?= /usr/local
endif
exec_prefix ?= $(prefix)
bindir ?= $(exec_prefix)/bin
mandir ?= $(prefix)/share/man
man1dir ?= $(mandir)/man1

help:
	@echo
	@echo "* Run 'make install' to install the script to $(bindir)"
	@echo "* Run 'make uninstall' to uninstall the script again."
	@echo "* You can pick a different install prefix than $(prefix) with"
	@echo "  make prefix=/other/prefix install"
	@echo

all:

clean:

install: $(DESTDIR)$(bindir)/git-archive-all $(DESTDIR)$(man1dir)/git-archive-all.1.gz

uninstall:
	rm $(DESTDIR)$(bindir)/git-archive-all
	rm -f $(DESTDIR)$(man1dir)/git-archive-all.1*

check:
	./test.bats

$(DESTDIR)$(bindir)/git-archive-all: git-archive-all $(DESTDIR)$(bindir)
	install -m755 $< $(DESTDIR)$(bindir)

$(DESTDIR)$(man1dir)/git-archive-all.1.gz: git-archive-all $(DESTDIR)$(man1dir)
	pod2man -r "" -c "Git Manual" $< | gzip -9cn > $@

$(DESTDIR)$(bindir) $(DESTDIR)$(man1dir):
	mkdir -p $@

.PHONY: all check clean help install uninstall

