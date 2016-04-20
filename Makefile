all: install
.PHONY: all install depclean distclean clean run

install:
	./install.sh

depclean: distclean
	yum erase freeradius -y
	rm -rf /etc/raddb
	rm -rf /usr/local/etc/raddb

distclean: clean
	rm -rf backup

clean:
	rm -rf freeradius*

run:
	radiusd -X
