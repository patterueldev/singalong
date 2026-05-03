cd infrastructure/local-release/master
# or `cd /Users/pat/Projects/PAT/singalong/infrastructure/local-release/master`
DOCKER_HOST=unix:///Users/pat/.lima/singalong-master/sock/docker.sock docker logs -f singalong-master
DOCKER_HOST=unix:///Users/pat/.lima/singalong-master/sock/docker.sock docker logs singalong-master
DOCKER_HOST=unix:///Users/pat/.lima/singalong-master/sock/docker.sock docker compose up -d --build
DOCKER_HOST=unix:///Users/pat/.lima/singalong-master/sock/docker.sock docker compose down