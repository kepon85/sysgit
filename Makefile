PREFIX ?= /usr/local
SYSCONFDIR ?= /etc
BINDIR ?= $(PREFIX)/bin
INSTALL ?= install

.PHONY: install uninstall

install:
	$(INSTALL) -m 0755 -D usr/local/bin/sysgit $(DESTDIR)$(BINDIR)/sysgit
	$(INSTALL) -m 0644 -D etc/sysgit.conf_default $(DESTDIR)$(SYSCONFDIR)/sysgit.conf_default
	@if [ ! -f "$(DESTDIR)$(SYSCONFDIR)/sysgit.conf" ]; then \
		$(INSTALL) -m 0644 -D etc/sysgit.conf_default $(DESTDIR)$(SYSCONFDIR)/sysgit.conf; \
	fi
	$(INSTALL) -m 0644 -D etc/bash_completion.d/sysgit $(DESTDIR)$(SYSCONFDIR)/bash_completion.d/sysgit
	$(INSTALL) -m 0644 -D etc/apt/apt.conf.d/90sysgit $(DESTDIR)$(SYSCONFDIR)/apt/apt.conf.d/90sysgit

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/sysgit
	rm -f $(DESTDIR)$(SYSCONFDIR)/sysgit.conf $(DESTDIR)$(SYSCONFDIR)/sysgit.conf_default
	rm -f $(DESTDIR)$(SYSCONFDIR)/bash_completion.d/sysgit
	rm -f $(DESTDIR)$(SYSCONFDIR)/apt/apt.conf.d/90sysgit
