# dweebui

Homepage: <https://dweebui.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `dweebui_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable dweebui to enable the app
ane.sh --up to install the app

If you want to access dweebui externally, don't forget to set `dweebui_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The dweebui web interface can be found at <http://ansible_nas_host_or_ip:port>.
