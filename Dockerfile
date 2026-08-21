# Multi-stage build for the payments-service canary demo.
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
COPY src ./src
# Community profile keeps the image build independent of Lightwell auth.
RUN mvn -B -Pci-community -DskipTests package

FROM eclipse-temurin:17-jre
ENV PORT=8080
EXPOSE 8080
COPY --from=build /build/target/payments-service.jar /app/payments-service.jar
USER 65532:65532
ENTRYPOINT ["java", "-jar", "/app/payments-service.jar"]
