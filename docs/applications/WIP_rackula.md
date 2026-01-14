# rackula

Homepage: <https://rackula.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `rackula_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable rackula to enable the app
ane.sh --up to install the app

If you want to access rackula externally, don't forget to set `rackula_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The rackula web interface can be found at <http://ansible_nas_host_or_ip:port>.
