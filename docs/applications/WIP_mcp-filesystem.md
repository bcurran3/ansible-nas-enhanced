# mcp-filesystem

Homepage: <https://mcp-filesystem.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `mcp-filesystem_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable mcp-filesystem to enable the app
ane.sh --up to install the app

If you want to access mcp-filesystem externally, don't forget to set `mcp-filesystem_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The mcp-filesystem web interface can be found at <http://ansible_nas_host_or_ip:port>.
