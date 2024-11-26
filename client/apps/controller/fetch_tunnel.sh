# Shell script to fetch the tunnel from ngrok
# 1. call `curl --location 'http://host.docker.internal:4040/api/tunnels'`
# 2. parse the JSON response to get the tunnel URL
# 3. find the tunnel named `api`
# 4. extract the public URL of the tunnel
# 5. replace the value of json from `/usr/share/nginx/html/tunnel.json` to {"api_tunnel_urltunnel_url": "http://<api_tunnel_urltunnel_url>", "is_tunnel": true}

# Add a delay of 5 seconds
sleep 5

# 1. call `curl --location 'http://host.docker.internal:4040/api/tunnels'`
response=$(curl --location 'http://host.docker.internal:4040/api/tunnels')

echo $response

# 2. parse the JSON response to get the tunnel URL
api_tunnel_url=$(echo $response | jq -r '.tunnels[] | select(.name == "api") | .public_url')
socket_storage_tunnel_url=$(echo $response | jq -r '.tunnels[] | select(.name == "socket_storage") | .public_url')

echo $api_tunnel_url
echo $socket_storage_tunnel_url


# 5. replace the value of json from `/usr/share/nginx/html/tunnel.json` to {"api_tunnel_urltunnel_url": "http://<api_tunnel_urltunnel_url>", "is_tunnel": true}
#echo "{\"api_tunnel_url\": \"$api_tunnel_urltunnel_url\", \"is_tunnel\": true}" > /usr/share/nginx/html/tunnel.json
echo "{\"api_tunnel_url\": \"$api_tunnel_url\", \"socket_storage_tunnel_url\": \"$socket_storage_tunnel_url\", \"is_tunnel\": true}" > /usr/share/nginx/html/tunnel.json

echo "Tunnel URL updated successfully."

# echo tunnel.json
cat /usr/share/nginx/html/tunnel.json