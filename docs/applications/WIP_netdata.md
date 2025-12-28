# netdata

Homepage: <https://netdata.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `netdata_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable netdata to enable the app
ane.sh --up to install the app

If you want to access netdata externally, don't forget to set `netdata_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The netdata web interface can be found at <http://ansible_nas_host_or_ip:port>.
