FROM azul/zulu-openjdk:21

WORKDIR /app

COPY /build/libs/api-0.0.1-SNAPSHOT.jar /app/app.jar
COPY /application-docker.yml /app/application-docker.yml
COPY /application-secrets.yml /app/application-secrets.yml

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]