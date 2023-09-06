FROM openjdk:17-alpine
MAINTAINER Alexander Lukyanchikov <sqshq@sqshq.com>

ADD ./admin-service/target/**.jar /app/admin-service.jar
CMD ["java", "-jar", "/app/admin-service.jar"]

EXPOSE 8080
