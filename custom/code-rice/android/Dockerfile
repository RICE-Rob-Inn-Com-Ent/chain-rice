# Kotlin/Android Development Dockerfile

FROM gradle:8-jdk21

WORKDIR /app

# Copy all files first
COPY . .

# Ensure gradle directory exists
RUN mkdir -p gradle/wrapper

# Build (skip if no build.gradle)
RUN if [ -f build.gradle ]; then gradle build || echo "Build failed, continuing..."; else echo "No build.gradle found, skipping build"; fi

EXPOSE 8080

CMD ["sh", "-c", "if [ -f build.gradle ]; then gradle run; else echo 'No build.gradle, container started'; sleep infinity; fi"]

