# Docker Guide

## Installation Prerequisites

1. Docker Desktop
2. MongoDB Compass (For viewing database)
3. Install the Docker extension in VS Code/Android Studio (To manage containers directly in code editors)

## Environment Setup

Copy/Download all files attached in this branch
1. For Flutter, place the .dockerignore and Dockerfile in the same path of **pubspec.yaml**
2. For Laravel, place the .dockerignore and Dockerfile in the same path of **.env**. Update the database.php and .env with the attached files here.

## Compose YML Files Configuration
The following attached docker compose yml files are separated to allow both dev testing and production (static):

**1. docker-compose.yml**
- For main deployment and production (run-only)
- To start a container, enter this command: docker-compose up -d

**2. docker-compose.dev.yml**
- For testing and development
- To start a container, enter this command: docker-compose -f docker-compose.dev.yml up -d


# For Production

## 1. Pull/Download Starbooks Images from Dockerhub

**Flutter**
docker pull dostnexus/flutter-starbooks:latest

**Laravel API**
docker pull dostnexus/laravel-starbooks-api:latest

## 2. Import CSV data into MongoDB

Copy/Download the CSV files attached inside the mongodb branch of this repository

## 3. Starting and Stopping the Application Containers

cd C:\Docker Compose (_Adjust to your Docker Compose file path_)
docker-compose up -d
docker-compose down (end container process)

# For Development and Testing

## 1. Get Dockerhub Username

docker login
(_Input your username and password_)

## 2. Building and Sharing Image to Dockerhub

**Flutter Image**
cd C:\flutter_projects (_Adjust to your Flutter file path_)
docker build -t dostnexus/flutter-starbooks:latest .
docker push dostnexus/flutter-starbooks:latest
   
**Laravel Image**
cd C:\laragon\www\api (_Adjust to your Laravel file path_)
docker build -t dostnexus/laravel-starbooks-api:latest .
docker push dostnexus/laravel-starbooks-api:latest

## 3. Starting and Stopping Docker Compose Containers

cd C:\Docker Compose (_Adjust to your Docker Compose file path_)
docker-compose -f docker-compose.dev.yml up -d
docker-compose -f docker-compose.dev.yml down

## 4. Accessing the application:

- Flutter: http://localhost:8080
- Laravel API: http://localhost:8000/api/region
- MongoDB: mongodb://localhost:27017

Visit the official Docker documentation for additional tutorials and guidance here:
https://docs.docker.com/get-started/introduction/
https://docs.docker.com/build/building/multi-stage/
