# crashlytic

Having file settings.conf:
```
[ftp]
name = "hello there, ftp uploading"
path = /tmp/
path<production> = /srv/var/tmp/
path<staging> = /srv/uploads/
path<ubuntu> = /etc/var/uploads
enabled = no
```

You can parse it like:
```
crashlytics = Crashlytics.new
config = crashlytics.load_config('settings.conf', :ubuntu)
config.ftp.to_h
=> {name: "hello there, ftp uploading", path: "/etc/var/uploads", enabled: false}
config.name
=> "hello there, ftp uploading"
config.path
=> "/etc/var/uploads"
```
