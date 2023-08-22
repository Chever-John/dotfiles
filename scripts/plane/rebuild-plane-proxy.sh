docker compose -f docker-compose.yml down
sleep 5

docker rmi plane-plane-proxy:latest

docker compose -f docker-compose.yml up -d