# Use the nginx:alpine image as the base
FROM nginx:alpine

# Install Java
RUN apk add --no-cache openjdk21

# Set the working directory
WORKDIR /app

# Copy the built Spring Boot application
COPY /api/build/libs/api-0.0.1-SNAPSHOT.jar /app/app.jar
COPY /api/src/main/resources/application-docker.yml /app/application-docker.yml
COPY /api/src/main/resources/application-secrets.yml /app/application-secrets.yml

# Copy Nginx configuration
COPY /nginx.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Start Nginx and the Spring Boot application
CMD ["sh", "-c", "java -jar /app/app.jar & nginx -g 'daemon off;'"]