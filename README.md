# crashlytic

/settings.conf
[ftp]
name = "hello there, ftp uploading"
path = /tmp/
path<production> = /srv/var/tmp/
path<staging> = /srv/uploads/
path<ubuntu> = /etc/var/uploads
enabled = no

crashlytics = Crashlytics.new
config = crashlytics.load_config('/settings.conf', :ubuntu)
=>
config.ftp = {:name=>"hello there, ftp uploading", :path=>"/etc/var/uploads", :enabled=>false}