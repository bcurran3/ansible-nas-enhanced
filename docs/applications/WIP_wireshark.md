# wireshark

Homepage: <https://wireshark.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `wireshark_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable wireshark to enable the app
ane.sh --up to install the app

If you want to access wireshark externally, don't forget to set `wireshark_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The wireshark web interface can be found at <http://ansible_nas_host_or_ip:port>.
