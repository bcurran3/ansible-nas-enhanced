# ansible-galaxy install -r requirements.yml
ansible-playbook -i inventories/supernas/inventory nas.yml -b -K $1 $2 $3 $4 $5
# --tags "taskname"

