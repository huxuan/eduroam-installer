install:
	./install.sh
clean:
	yum erase freeradius -y
	rm -rf /etc/raddb
	rm -rf /usr/local/etc/raddb
	rm -rf backup
	rm -rf freeradius*
run:
	radiusd -X
