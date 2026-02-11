# Stage 1: Build the Flutter web app
FROM ubuntu:22.04 AS build

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install Flutter dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter SDK (stable channel)
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

# Pre-download Flutter artifacts
RUN flutter doctor -v
RUN flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy pubspec files first (for better caching)
COPY pubspec.* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of your Flutter project
COPY . .

# Build the Flutter web app for production
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy the built web files from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Nginx starts automatically
CMD ["nginx", "-g", "daemon off;"]