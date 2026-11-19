#!/bin/bash
set -e

TAG=$(git rev-parse --short HEAD)
IMAGE="localhost:5000/pagosya-api"

echo "Desplegando version: $TAG"

docker build \
  --build-arg APP_VERSION="$TAG" \
  -t "$IMAGE:$TAG" \
  app/

docker push "$IMAGE:$TAG"

if TAG="$TAG" docker compose up -d; then
    echo "Esperando a que la API responda..."
    sleep 5

    if curl -fsS http://localhost:8080/; then
        echo "Despliegue exitoso"
        echo "$TAG" > .last-good
        exit 0
    fi
fi

echo "Error en el despliegue. Ejecutando rollback..."

if [ -f .last-good ]; then
    PREVIOUS_TAG=$(cat .last-good)
    TAG="$PREVIOUS_TAG" docker compose up -d
    echo "Rollback completado a $PREVIOUS_TAG"
else
    echo "No existe una version anterior para recuperar"
fi

exit 1