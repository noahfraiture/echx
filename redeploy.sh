docker context use hostinger
docker build -t echx-frontend:prod ./frontend
docker build -t echx-backend:prod ./backend
docker stack down echx
docker stack deploy --with-registry-auth -c compose.yml echx
