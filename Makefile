PREFIX ?= /usr/local
SYSCONFDIR ?= /etc
BINDIR ?= $(PREFIX)/bin
INSTALL ?= install

.PHONY: install uninstall

install:
	$(INSTALL) -m 0755 -D usr/local/bin/sysgit $(DESTDIR)$(BINDIR)/sysgit
	@if [ -f "$(DESTDIR)$(SYSCONFDIR)/sysgit.conf" ]; then \
		$(INSTALL) -m 0644 -D etc/sysgit.conf $(DESTDIR)$(SYSCONFDIR)/sysgit.conf.new; \
		echo "sysgit.conf existe deja, installation dans sysgit.conf.new"; \
	else \
		$(INSTALL) -m 0644 -D etc/sysgit.conf $(DESTDIR)$(SYSCONFDIR)/sysgit.conf; \
	fi
	$(INSTALL) -m 0644 -D etc/bash_completion.d/sysgit $(DESTDIR)$(SYSCONFDIR)/bash_completion.d/sysgit

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/sysgit
	rm -f $(DESTDIR)$(SYSCONFDIR)/sysgit.conf $(DESTDIR)$(SYSCONFDIR)/sysgit.conf.new
	rm -f $(DESTDIR)$(SYSCONFDIR)/bash_completion.d/sysgit
