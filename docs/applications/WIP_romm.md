# romm

Homepage: <https://romm.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `romm_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable romm to enable the app
ane.sh --up to install the app

If you want to access romm externally, don't forget to set `romm_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The romm web interface can be found at <http://ansible_nas_host_or_ip:port>.
