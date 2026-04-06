# Docker Guide

## Installation Prerequisites

1. Docker Desktop
2. MongoDB Compass (For viewing database)
3. Install the Docker extension in VS Code/Android Studio (To manage containers directly in code editors)

## Environment Setup

Copy/Download all files attached in this branch
1. For Flutter, place the **.dockerignore** and **Dockerfile** in the same path as **pubspec.yaml**
2. For Laravel, place the **.dockerignore** and **Dockerfile** in the same path as **.env**.
3. Update the **database.php** and **.env** with the attached files in this branch.

## Compose YML Files Configuration
The following attached docker compose yml files are separated to allow both dev testing and production (static):

**1. docker-compose.yml**
- For main deployment and production (run-only)
- To start a container, enter this command:
```
docker-compose up -d
```

**2. docker-compose.dev.yml**
- For testing and development
- To start a container, enter this command:
```
docker-compose -f docker-compose.dev.yml up -d
```

# For Production

## 1. Pull/Download Starbooks Images from Dockerhub

**Flutter**
```
docker pull dostnexus/flutter-starbooks:latest
```

**Laravel API**
```
docker pull dostnexus/laravel-starbooks-api:latest

# In case errors occur:
docker-compose down
docker-compose up -d --force-recreate laravel-api
docker-compose restart laravel-api
```

**Whiz Battle Server**
```
docker pull dostnexus/whiz-battle-server:latest
```

## 2. Import CSV data into MongoDB

Copy/Download the CSV files attached inside the mongodb branch of this repository:
- [MongoDB Files](https://github.com/APC-SoCIT/APC_2025_2026_T1_MI232_G06-DOST-STARBOOKS-Whiz-Challenge-/tree/mongodb)

## 3. Starting and Stopping the Application Containers
- Note: Adjust to your Docker Compose file path
```
cd C:\Docker Compose
docker-compose up -d
docker-compose down (end container process)
```

# For Development and Testing

## 1. Get Dockerhub Username
```
docker login
```
(_Input your username and password_)

## 2. Building and Sharing Image to Dockerhub

**Flutter Image**
- Note: Adjust to your Flutter file path
```
cd C:\flutter_projects
docker build -t dostnexus/flutter-starbooks:latest .
docker push dostnexus/flutter-starbooks:latest
```
   
**Laravel Image**
- Note: Adjust to your Laravel file path
```
cd C:\laragon\www\api
docker build -t dostnexus/laravel-starbooks-api:latest .
docker push dostnexus/laravel-starbooks-api:latest
```
**Whiz Battle Server Image**
- Note: Adjust to your Laravel file path
```
C:\laragon\www\whiz-battle-server
docker build -t dostnexus/whiz-battle-server:latest .
docker push dostnexus/whiz-battle-server:latest
```

## 3. Starting and Stopping Docker Compose Containers
- Note: Adjust to your Docker Compose file path
```
cd C:\Docker Compose
docker-compose -f docker-compose.dev.yml up -d
docker-compose -f docker-compose.dev.yml down
```

# Configuring Whiz Battle Server
Choose 1 PC/Device to act as HOST

On the host computer (Windows):

1. Press Windows key, search "Windows Defender Firewall"
2. Click "Advanced settings"
3. Click "Inbound Rules" (left side)
4. Click "New Rule" (right side)
5. Select "Port" → Next
6. Select "TCP" → Specific ports: 8080, 8000, 8085 → Next
7. Select "Allow the connection" → Next
8. Check all boxes (Domain, Private, Public) → Next
9. Name: Starbooks Docker → Finish

- Type this in terminal (CMD):
```
ipconfig
```
- Search for your IP address (Ex: IPv4 Address. . . . . . : 192.168.1.100)

cd C:\starbooks
docker-compose up -d
```
## Access the App

**Host (plays locally):**
```
Opens browser → http://localhost:8080
```
**Guest (connects to host):**
```
Opens browser → http://192.168.1.100:8080
(Replace with actual host IP)


## Accessing the application:

- Flutter: http://localhost:8080
- Laravel API: http://localhost:8000/api/region
- MongoDB: mongodb://localhost:27017 (Connect to MongoDB Compass)

Visit the official Docker documentation for additional tutorials and guidance here:
- https://docs.docker.com/get-started/introduction/
- https://docs.docker.com/build/building/multi-stage/
