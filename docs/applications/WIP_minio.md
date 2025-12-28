# minio

Homepage: <https://minio.com/>
Image: <https://link_to_docker_image_used.com>

This is where you would have the developer's description of the application.

## Usage

Set `minio_enabled: true` in your `inventories/<your_inventory>/nas.yml` file.

ane.sh --enable minio to enable the app
ane.sh --up to install the app

If you want to access minio externally, don't forget to set `minio_available_externally: true` in your `inventories/<your_inventory>/nas.yml` file.

!---> mention dockflare here with cloduflare account and domain

The default credentials are admin:password

The minio web interface can be found at <http://ansible_nas_host_or_ip:port>.
