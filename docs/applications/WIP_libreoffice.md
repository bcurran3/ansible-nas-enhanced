# libreoffice

Homepage: <https://libreoffice.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `libreoffice_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable libreoffice to enable the app
ane.sh --up to install the app

If you want to access libreoffice externally, don't forget to set `libreoffice_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The libreoffice web interface can be found at <http://ansible_nas_host_or_ip:port>.
