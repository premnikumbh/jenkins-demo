# Use an official Maven base image
FROM maven:3.8.6-openjdk-11 as builder

# Set the working directory
WORKDIR /app

# Copy the pom.xml and the source code
COPY pom.xml .
COPY src ./src

# Build the application using Maven
RUN mvn clean install

# Create a new image with a slim JRE for the runtime environment
FROM openjdk:11-jre-slim

# Copy the built JAR file from the previous stage
COPY --from=builder /app/target/simple-java-maven-app-1.0-SNAPSHOT.jar /app/simple-java-maven-app.jar

# Command to run the application
ENTRYPOINT ["java", "-jar", "/app/simple-java-maven-app.jar"]
