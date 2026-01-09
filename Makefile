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
	$(INSTALL) -m 0644 -D etc/sysgit.ignore_default $(DESTDIR)$(SYSCONFDIR)/sysgit.ignore_default
	@if [ ! -f "$(DESTDIR)$(SYSCONFDIR)/sysgit.ignore" ]; then \
		$(INSTALL) -m 0644 -D etc/sysgit.ignore_default $(DESTDIR)$(SYSCONFDIR)/sysgit.ignore; \
	fi
	$(INSTALL) -m 0644 -D etc/bash_completion.d/sysgit $(DESTDIR)$(SYSCONFDIR)/bash_completion.d/sysgit
	$(INSTALL) -m 0644 -D etc/apt/apt.conf.d/90sysgit $(DESTDIR)$(SYSCONFDIR)/apt/apt.conf.d/90sysgit
	$(INSTALL) -m 0644 -D etc/systemd/system/sysgit-autocommit.service $(DESTDIR)$(SYSCONFDIR)/systemd/system/sysgit-autocommit.service
	$(INSTALL) -m 0644 -D etc/systemd/system/sysgit-autocommit.timer $(DESTDIR)$(SYSCONFDIR)/systemd/system/sysgit-autocommit.timer

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/sysgit
	rm -f $(DESTDIR)$(SYSCONFDIR)/sysgit.conf $(DESTDIR)$(SYSCONFDIR)/sysgit.conf_default
	rm -f $(DESTDIR)$(SYSCONFDIR)/sysgit.ignore $(DESTDIR)$(SYSCONFDIR)/sysgit.ignore_default
	rm -f $(DESTDIR)$(SYSCONFDIR)/bash_completion.d/sysgit
	rm -f $(DESTDIR)$(SYSCONFDIR)/apt/apt.conf.d/90sysgit
	rm -f $(DESTDIR)$(SYSCONFDIR)/systemd/system/sysgit-autocommit.service
	rm -f $(DESTDIR)$(SYSCONFDIR)/systemd/system/sysgit-autocommit.timer
