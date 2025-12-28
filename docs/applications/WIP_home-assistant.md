# home-assistant

Homepage: <https://home-assistant.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `home-assistant_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable home-assistant to enable the app
ane.sh --up to install the app

If you want to access home-assistant externally, don't forget to set `home-assistant_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The home-assistant web interface can be found at <http://ansible_nas_host_or_ip:port>.
