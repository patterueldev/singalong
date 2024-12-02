FROM azul/zulu-openjdk:21

WORKDIR /app

COPY /api/build/libs/api-0.0.1-SNAPSHOT.jar /app/app.jar
COPY /api/src/main/resources/application-docker.yml /app/application-docker.yml
COPY /api/src/main/resources/application-secrets.yml /app/application-secrets.yml

EXPOSE 8080 9092

ENTRYPOINT ["java", "-jar", "app.jar"]