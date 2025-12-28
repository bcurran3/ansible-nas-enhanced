# minecraft-bedrock-server

Homepage: <https://minecraft-bedrock-server.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `minecraft-bedrock-server_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable minecraft-bedrock-server to enable the app
ane.sh --up to install the app

If you want to access minecraft-bedrock-server externally, don't forget to set `minecraft-bedrock-server_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The minecraft-bedrock-server web interface can be found at <http://ansible_nas_host_or_ip:port>.
