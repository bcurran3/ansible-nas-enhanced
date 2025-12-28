# stirling-pdf

Homepage: <https://stirling-pdf.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `stirling-pdf_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable stirling-pdf to enable the app
ane.sh --up to install the app

If you want to access stirling-pdf externally, don't forget to set `stirling-pdf_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The stirling-pdf web interface can be found at <http://ansible_nas_host_or_ip:port>.
