# Use the official Nginx image as the base image
FROM nginx:alpine

# Copy the built Flutter web files to the Nginx HTML directory
COPY build/web /usr/share/nginx/html

# Copy the Nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 to the outside world
EXPOSE 80

# Start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]