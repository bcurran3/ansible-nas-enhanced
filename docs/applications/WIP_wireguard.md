# wireguard

Homepage: <https://wireguard.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `wireguard_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable wireguard to enable the app
ane.sh --up to install the app

If you want to access wireguard externally, don't forget to set `wireguard_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The wireguard web interface can be found at <http://ansible_nas_host_or_ip:port>.
