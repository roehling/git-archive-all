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
ifneq ($(PREFIX),)
prefix ?= $(PREFIX)
endif
ifneq ($(DESTDIR),)
prefix ?= /usr
endif
ifneq ($(shell id -u),0)
prefix ?= $(HOME)/.local
else
prefix ?= /usr/local
endif

bindir ?= bin
mandir ?= share/man/man1

help:
	@echo
	@echo "* Run 'make install' to install the script to $(prefix)/$(bindir)"
	@echo "* Run 'make uninstall' to uninstall the script again."
	@echo "* You can pick a different install prefix than $(prefix) with"
	@echo "  make prefix=/other/prefix install"
	@echo

install: $(DESTDIR)$(prefix)/$(bindir)/git-archive-all $(DESTDIR)$(prefix)/$(mandir)/git-archive-all.1.gz

uninstall:
	rm $(DESTDIR)$(prefix)/$(bindir)/git-archive-all
	rm -f $(DESTDIR)$(prefix)/$(mandir)/git-archive-all.1.gz

$(DESTDIR)$(prefix)/$(bindir)/git-archive-all: git-archive-all $(DESTDIR)$(prefix)/$(bindir)
	install -m755 $< $(DESTDIR)$(prefix)/$(bindir)

$(DESTDIR)$(prefix)/$(mandir)/git-archive-all.1.gz: git-archive-all $(DESTDIR)$(prefix)/$(mandir)
	pod2man -r "" -c "Git Manual" $< > $(basename $@) && gzip -9fn $(basename $@)

$(DESTDIR)$(prefix)/$(bindir) $(DESTDIR)$(prefix)/$(mandir):
	mkdir -p $@

.PHONY: install uninstall

