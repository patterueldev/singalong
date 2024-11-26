# Use the official Nginx image as the base image
FROM nginx:alpine

# Install curl and jq
RUN apk add --no-cache curl jq

# Copy the built Flutter web files to the Nginx HTML directory
COPY build/web /usr/share/nginx/html

# Copy the Nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the fetch_tunnel.sh script
COPY fetch_tunnel.sh /fetch_tunnel.sh

# Make the fetch_tunnel.sh script executable
RUN chmod +x /fetch_tunnel.sh

# Expose port 80 to the outside world
EXPOSE 80

# Start Nginx when the container starts and execute the fetch_tunnel.sh script
CMD ["sh", "-c", "/fetch_tunnel.sh && nginx -g 'daemon off;'"]