#!/usr/bin/env bash

#
# Release Dockerfile Build Test Script
#
# Purpose:
#   Manually test building release Dockerfiles locally.
#   Verifies both Master and Node release images build successfully.
#
# Usage:
#   ./scripts/test-release-builds.sh              # Test both
#   ./scripts/test-release-builds.sh master       # Test master only
#   ./scripts/test-release-builds.sh node         # Test node only
#   ./scripts/test-release-builds.sh --clean      # Remove test images
#
# Examples:
#   ./scripts/test-release-builds.sh
#   ./scripts/test-release-builds.sh master
#   ./scripts/test-release-builds.sh node --verbose
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_BUILDX_BUILDER="singalong-builder"

# Parse arguments
SERVICE="${1:-all}"
CLEAN=false
VERBOSE=false

if [[ "$SERVICE" == "--clean" ]]; then
  CLEAN=true
  SERVICE="all"
fi

if [[ "$SERVICE" == "--verbose" ]] || [[ "$2" == "--verbose" ]]; then
  VERBOSE=true
fi

# Functions
print_header() {
  echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

check_docker() {
  if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
  fi
  print_success "Docker found"
}

check_buildx() {
  if ! docker buildx inspect $DOCKER_BUILDX_BUILDER &> /dev/null; then
    print_info "Creating docker buildx builder: $DOCKER_BUILDX_BUILDER"
    docker buildx create --name $DOCKER_BUILDX_BUILDER --use
    print_success "Buildx builder created"
  else
    print_success "Docker buildx available"
  fi
}

clean_images() {
  print_header "Cleaning up Docker images"
  
  local images_removed=0
  
  if docker image inspect "singalong-master:release-test" &> /dev/null; then
    docker rmi "singalong-master:release-test"
    ((images_removed++))
    print_success "Removed singalong-master:release-test"
  fi
  
  if docker image inspect "singalong-node:release-test" &> /dev/null; then
    docker rmi "singalong-node:release-test"
    ((images_removed++))
    print_success "Removed singalong-node:release-test"
  fi
  
  if [ $images_removed -eq 0 ]; then
    print_info "No test images found to remove"
  fi
}

build_master() {
  print_header "Building Master Release Image"
  
  cd "$PROJECT_ROOT"
  
  print_info "Building from: apps/singalong-master/Dockerfile"
  
  local docker_cmd="docker build"
  [ "$VERBOSE" = true ] && docker_cmd="$docker_cmd --progress=plain"
  
  if $docker_cmd \
    -f apps/singalong-master/Dockerfile \
    -t singalong-master:release-test \
    apps/singalong-master/; then
    print_success "Master release image built successfully"
    
    # Get image size
    local size=$(docker image inspect --format='{{.Size}}' singalong-master:release-test | numfmt --to=iec 2>/dev/null || docker image inspect --format='{{.Size}}' singalong-master:release-test)
    print_info "Image size: $size"
    
    return 0
  else
    print_error "Failed to build master release image"
    return 1
  fi
}

build_node() {
  print_header "Building Node Release Image"
  
  cd "$PROJECT_ROOT"
  
  print_info "Building from: apps/singalong-node/Dockerfile"
  
  local docker_cmd="docker build"
  [ "$VERBOSE" = true ] && docker_cmd="$docker_cmd --progress=plain"
  
  if $docker_cmd \
    -f apps/singalong-node/Dockerfile \
    -t singalong-node:release-test \
    apps/singalong-node/; then
    print_success "Node release image built successfully"
    
    # Get image size
    local size=$(docker image inspect --format='{{.Size}}' singalong-node:release-test | numfmt --to=iec 2>/dev/null || docker image inspect --format='{{.Size}}' singalong-node:release-test)
    print_info "Image size: $size"
    
    return 0
  else
    print_error "Failed to build node release image"
    return 1
  fi
}

test_master_health() {
  print_info "Testing Master health endpoint..."
  
  # Start container in background
  local container_id=$(docker run -d -p 5001:5001 singalong-master:release-test)
  
  # Wait for service to start
  sleep 5
  
  # Test health endpoint
  if curl -s http://localhost:5001/health > /dev/null 2>&1; then
    print_success "Master health check passed"
    docker stop $container_id > /dev/null
    return 0
  else
    print_warning "Master health check failed (service might still be starting)"
    docker stop $container_id > /dev/null
    return 1
  fi
}

test_node_health() {
  print_info "Testing Node health endpoint..."
  
  # Start container in background
  local container_id=$(docker run -d -p 5002:5002 singalong-node:release-test)
  
  # Wait for service to start
  sleep 5
  
  # Test health endpoint
  if curl -s http://localhost:5002/health > /dev/null 2>&1; then
    print_success "Node health check passed"
    docker stop $container_id > /dev/null
    return 0
  else
    print_warning "Node health check failed (service might still be starting)"
    docker stop $container_id > /dev/null
    return 1
  fi
}

main() {
  print_header "Release Dockerfile Build Test"
  
  # Check prerequisites
  check_docker
  check_buildx
  
  # Handle cleanup
  if [ "$CLEAN" = true ]; then
    clean_images
    exit 0
  fi
  
  local failed=false
  
  # Build services
  if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "master" ]]; then
    if ! build_master; then
      failed=true
    fi
  fi
  
  if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "node" ]]; then
    if ! build_node; then
      failed=true
    fi
  fi
  
  # Summary
  echo ""
  print_header "Build Summary"
  
  if [ "$failed" = true ]; then
    print_error "Some builds failed"
    exit 1
  else
    print_success "All builds completed successfully!"
    echo ""
    print_info "Test images created:"
    docker image ls | grep "singalong-" | grep "release-test"
    echo ""
    print_info "To clean up test images, run: ./scripts/test-release-builds.sh --clean"
  fi
}

# Run main
main
