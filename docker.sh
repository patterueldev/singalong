#!/bin/bash
set -e

root=$(pwd)
fluttercontrollerapp="$root/client/apps/controller"

# Function to handle errors
handle_error() {
    echo "Error occurred in script at line: $1"
    exit 1
}

# Trap errors and call handle_error function
trap 'handle_error $LINENO' ERR

# Format
./gradlew ktlintFormat

# Build the project
./gradlew build
echo "Gradle build completed successfully."

# Build the Flutter web project
cd $fluttercontrollerapp
flutter build web --target=lib/main_web.dart
echo "Flutter web build completed successfully."
cd $root

# Bring down any running containers
docker compose down --remove-orphans
echo "Docker containers stopped successfully."

# Clean up any dangling images
docker image prune -f
echo "Docker images cleaned up successfully."

# Bring up the containers in detached mode
docker compose up -d --build
echo "Docker containers started successfully."