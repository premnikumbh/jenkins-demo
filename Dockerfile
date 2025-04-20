# Use Maven image to build the app
FROM maven:3.8.5-openjdk-17 AS build
WORKDIR /app
COPY . . 
RUN mvn clean package

# Use JRE image to run the app
FROM openjdk:17-jdk-slim
COPY --from=build /app/target/*.jar /app/app.jar
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
