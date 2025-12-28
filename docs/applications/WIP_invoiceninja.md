# invoiceninja

Homepage: <https://invoiceninja.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `invoiceninja_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable invoiceninja to enable the app
ane.sh --up to install the app

If you want to access invoiceninja externally, don't forget to set `invoiceninja_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The invoiceninja web interface can be found at <http://ansible_nas_host_or_ip:port>.
