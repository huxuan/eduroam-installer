install:
	./install.sh
clean:
	yum erase freeradius -y
	rm -rf /etc/raddb
	rm -rf backup
