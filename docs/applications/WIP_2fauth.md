# 2fauth

Homepage: <https://2fauth.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `2fauth_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable 2fauth to enable the app
ane.sh --up to install the app

If you want to access 2fauth externally, don't forget to set `2fauth_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The 2fauth web interface can be found at <http://ansible_nas_host_or_ip:port>.
