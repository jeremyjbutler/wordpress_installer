# wordpress_installer


This script will securely install wordpress on a linux server running apache, it installs w3tc by default and supports installation of additional plugins and themes. The admin area is also secured with an additional basic HTTP AUTH. It also assumes the server is running proftpd because thats how the updates and plugin installs will run.


Requirements: 
Redhat Linux
Apache with mod_php
Proftpd
wget
php
