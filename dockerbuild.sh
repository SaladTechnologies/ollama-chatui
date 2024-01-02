#!/bin/bash

# Set the name of the Docker image
IMAGE_NAME=${1:-"ollama"}

# Set the version of the Docker image
VERSION=${2:-"1.0.0"}

# Set the name of the Azure Container Registry
ACR_NAME=${3:-"acrsaladdev"}

# Build the Docker image
docker build -t $IMAGE_NAME ./

# Tag the Docker image with the ACR name and version
docker tag $IMAGE_NAME $ACR_NAME.azurecr.io/$IMAGE_NAME:$VERSION

# Log in to the Azure Container Registry
az acr login --name $ACR_NAME

# Push the Docker image to the Azure Container Registry
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:$VERSION