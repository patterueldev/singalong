# TODO: TEMPORARY DEPLOYMENT; we need to configure the actual project's Dockerfile
# THIS IS just a temporary deployment for the UI Builder project for quick testing
# Use the official Nginx image as the base image
FROM nginx:alpine

# Copy the built Flutter web files to the Nginx HTML directory
# TODO: TEMPORARY DEPLOYMENT; we need to configure the actual project's Dockerfile
COPY apps/uibuilder/build/web /usr/share/nginx/html

# Expose port 80 to the outside world
EXPOSE 80

# Start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]