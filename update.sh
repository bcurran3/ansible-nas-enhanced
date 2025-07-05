# BEHIND=`git rev-list ...@{u} --count`
# git log -$BEHIND ...@{u} --pretty=format:"%h - %an, %ar : %s"
# ansible-galaxy install -r requirements.yml
ansible-playbook -i inventories/supernas/inventory nas.yml -b -K $1 $2 $3 $4 $5 $6 $7 $8 $9 ${10}
# --tags "taskname"
# prune docker stuff to save space
#echo y | docker image prune
#echo y | docker volume prune

