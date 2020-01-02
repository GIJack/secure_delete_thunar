PREFIX = "usr/local/"
install:
	install -Dm 644 shred.png "$(DESTDIR)/$(PREFIX)/share/pixmaps/shred.png"
	install -Dm 755 srm_guified.sh "$(DESTDIR)/$(PREFIX)/share/thunar_srm/srm_guified.sh"
	install -Dm 755 LICENSE "$(DESTDIR)/$(PREFIX)/share/thunar_srm/LICENSE"
	install -Dm 644 secure_delete.uca.xml "$(DESTDIR)/$(PREFIX)/share/thunar_srm/secure_delete.uca.xml"
