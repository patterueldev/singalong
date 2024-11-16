#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <port>"
  exit 1
fi

PORT=$1

while true; do
  PID=$(lsof -ti :$PORT)

  if [ -z "$PID" ]; then
    echo "No process is using port $PORT."
    break
  fi

  echo "Killing process $PID using port $PORT..."
  kill -9 $PID

  # Pause for a moment to allow the process to fully terminate
  sleep 1
done