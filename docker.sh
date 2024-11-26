#!/bin/bash
set -e

root=$(pwd)
api="$root/server"
fluttercontrollerapp="$root/client/apps/controller"
flutteradminapp="$root/client/apps/admin"

# Function to handle errors
handle_error() {
    echo "Error occurred in script at line: $1"
    exit 1
}

# Trap errors and call handle_error function
trap 'handle_error $LINENO' ERR

# Parse parameters
only=""
for arg in "$@"; do
  case $arg in
    --only=*)
      only="${arg#*=}"
      shift
      ;;
    *)
      ;;
  esac
done

# Function to build the api
build_api() {
  cd $api
  ./gradlew ktlintFormat
  ./gradlew build
  echo "Gradle build completed successfully."
  cd $root
}

# Function to build the client
build_controller() {
  cd $fluttercontrollerapp
  flutter build web --target=lib/main_web.dart
  echo "Flutter client build completed successfully."
  cd $root
}

# Function to build the admin
build_admin() {
  cd $flutteradminapp
  flutter build web --target=lib/main_web.dart
  echo "Flutter admin build completed successfully."
  cd $root
}

# Build components based on the --only parameter
if [ -z "$only" ]; then
  build_api
  build_controller
  build_admin
else
  IFS=',' read -ra components <<< "$only"
  for component in "${components[@]}"; do
    case $component in
      server)
        build_api
        ;;
      client)
        build_controller
        ;;
      admin)
        build_admin
        ;;
      nginx)
        echo "Nginx does not require a build."
        ;;
      ngrok)
        echo "Ngrok does not require a build."
        ;;
      *)
        echo "Unknown component: $component"
        exit 1
        ;;
    esac
  done
fi

# Docker operations based on the --only parameter
if [ -z "$only" ]; then
  # Bring down any running containers
  docker compose down --remove-orphans
  echo "Docker containers stopped successfully."

  # Clean up any dangling images
  docker image prune -f
  echo "Docker images cleaned up successfully."

  # Bring up all containers in detached mode
  docker compose up -d --build
  echo "Docker containers started successfully."
else
  # Bring up specific services in detached mode
  IFS=',' read -ra services <<< "$only"
  docker compose up -d --build "${services[@]}"
  echo "Docker services started successfully."
fi