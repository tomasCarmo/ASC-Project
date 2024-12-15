sudo apt update

# INSTALL NGINX
sudo apt install nginx

# HTTPS
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt

# RUN MAIN.PY
# sudo python3 CSA-Project/main.py

# START REDIS CLUSTER
#sudo apt install redis-server
#redis-server /path/to/redis.conf
#redis-cli --cluster create <node1>:6379 <node2>:6379 <node3>:6379 <node4>:6379 <node5>:6379 <node6>:6379 --cluster-replicas 1
