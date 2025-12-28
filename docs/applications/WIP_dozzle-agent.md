# dozzle-agent

Homepage: <https://dozzle-agent.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `dozzle-agent_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable dozzle-agent to enable the app
ane.sh --up to install the app

If you want to access dozzle-agent externally, don't forget to set `dozzle-agent_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The dozzle-agent web interface can be found at <http://ansible_nas_host_or_ip:port>.
