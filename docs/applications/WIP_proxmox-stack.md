# pve

Homepage: <https://pve.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `pve_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable pve to enable the app
ane.sh --up to install the app

If you want to access pve externally, don't forget to set `pve_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The pve web interface can be found at <http://ansible_nas_host_or_ip:port>.
