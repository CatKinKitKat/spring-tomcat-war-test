# Spring Boot WAR on Standalone Tomcat

This project demonstrates packaging a Spring Boot application as a WAR and deploying it to a standalone Apache Tomcat server (including via Docker).

## Overview: JAR vs WAR in Spring Boot
- JAR: The common Spring Boot packaging that embeds Tomcat (or another server). Run with `java -jar`. Simple, self-contained.
- WAR: Package the app as a web archive and deploy it to an external/standalone Tomcat. Useful when you must use an existing Tomcat or a shared app server.

Key differences when building a WAR:
- The main class extends `SpringBootServletInitializer` to support servlet container bootstrapping.
- The app is packaged with `war` packaging in `pom.xml` and excludes the embedded Tomcat from runtime scope.
- The WAR is deployed under a web context path, derived from the WAR name (e.g., `test.war` -> `/test`).

In this repo, the entrypoint is `eu.europa.emsa.starabm.test.Application`, which extends `SpringBootServletInitializer`.

## How it boots on Tomcat
- Tomcat scans the WAR, loads Spring’s `SpringBootServletInitializer`, and initializes the Spring ApplicationContext.
- The app runs behind Tomcat’s HTTP stack; your endpoints are accessible under `http://localhost:8080/<contextPath>/...`.
- The context path is typically the WAR filename without the `.war` extension (configurable via Tomcat or copy location).

## Docker-based Tomcat deployment
The included `Dockerfile` follows the standard pattern: copy the built WAR into the Tomcat webapps folder.

```
FROM tomcat:9-jdk11
ARG WAR_FILE=test.war
ARG CONTEXT_PATH=test
COPY target/${WAR_FILE} /usr/local/tomcat/webapps/${CONTEXT_PATH}.war
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget --spider -q http://localhost:8080/ || exit 1
CMD ["catalina.sh", "run"]
```

After building and running the container, your app is available at:
- `http://localhost:8080/test/api/hello`

## Redeploy scripts
Use the provided scripts to rebuild the WAR, rebuild the Docker image, and restart the Tomcat container.

- Bash (Linux/macOS, WSL, Git Bash):
  ```bash
  chmod +x scripts/redeploy.sh
  ./scripts/redeploy.sh
  # Optional overrides via env: IMAGE_NAME, CONTAINER_NAME, PORT, WAR_FILE, CONTEXT_PATH
  ```

- PowerShell (Windows):
  ```powershell
  .\scripts\redeploy.ps1
  # Optional parameter overrides
  .\scripts\redeploy.ps1 -ImageName tomcat9:latest -ContainerName tomcat -Port 8080 -WarFile test.war -ContextPath test
  ```

Both scripts perform:
1) `mvn clean package` to build the WAR
2) Stop/remove existing `tomcat` container
3) `docker build` with WAR/context args
4) `docker run` on port 8080 with restart policy

## Configuration in WAR deployments
- Properties: Primary file is `src/main/resources/application.properties`. The app also tries to load `/configuration/application.properties` from the filesystem (optional), allowing external config.
- Context path: Tomcat decides the context path by the WAR name (`test.war` => `/test`). Adjust by changing the WAR file name or Tomcat config.
- Environment variables: Spring Boot can read properties via environment variables (e.g., `SPRING_DATASOURCE_URL`). This is convenient with containers.

### Security
By default, Spring Security protects endpoints. This project includes a `SecurityConfig` that:
- Permits all requests (`anyRequest().permitAll()`)
- Disables CSRF, form login, and HTTP Basic, so no login page is shown

Adjust the configuration to protect specific paths in production.

### Database considerations
If your app needs a database:
- Set real `spring.datasource.*` properties (URL, username, password, driver) and include the JDBC driver dependency.
- For example, PostgreSQL:
  ```properties
  spring.datasource.url=jdbc:postgresql://db-host:5432/yourdb
  spring.datasource.username=youruser
  spring.datasource.password=yourpass
  spring.datasource.driver-class-name=org.postgresql.Driver
  ```
- Include the driver in `pom.xml`:
  ```xml
  <dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
  </dependency>
  ```

If you want the app to start without a DB, this project disables JDBC auto-configuration via:
```
spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
```
Remove that line when you provide a real datasource and want Liquibase/JPA to initialize.

## Local testing
- Browser:
  - Default greeting: `http://localhost:8080/test/api/hello`
  - Named greeting: `http://localhost:8080/test/api/hello?name=Alice`
- PowerShell:
  ```powershell
  Invoke-WebRequest -UseBasicParsing http://localhost:8080/test/api/hello
  Invoke-WebRequest -UseBasicParsing "http://localhost:8080/test/api/hello?name=Alice"
  ```

## Troubleshooting
- Login page appears: Ensure `SecurityConfig` is active and that you rebuilt/redeployed the WAR.
- 404 Not Found: Check the context path (`/test` by default) and that the WAR was copied to Tomcat as `test.war`.
- DB driver class errors: Provide a valid `spring.datasource.driver-class-name` and include the driver dependency, or keep `DataSourceAutoConfiguration` excluded for non-DB runs.
- Container health is starting/failed: Wait for startup or check logs with `docker logs tomcat`.

## Why WAR deployments are used
- Organizational requirements to deploy in a shared Tomcat.
- Operations prefer centralized server management and monitoring.
- Allows multiple apps on one Tomcat instance (with distinct context paths).

## References
- Spring Boot reference: Packaging for production and servlet containers
- Tomcat docs: Web application deployment and context paths

## Architecture diagram (ASCII)

```
+---------------------------+                          +-----------------------------+
|         Client            |  HTTP requests/responses |        Host / Docker        |
| (Browser, curl, Postman)  | <----------------------> |  runs Apache Tomcat server  |
+---------------------------+                          +-----------------------------+
                                                         |
                                                         | starts
                                                         v
                                               +---------------------+
                                               |      Tomcat         |
                                               |  (Standalone 9.x)   |
                                               +----------+----------+
                                                          |
                                                          | deploys WAR as context
                                                          v
                                       +------------------+------------------+
                                       |      Spring Boot WAR (test.war)     |
                                       |  Context path: /test                |
                                       |  Controllers, Services, Config      |
                                       +------------------+------------------+
                                                          ^
                                                          |
                                    e.g. /test/api/hello  |  mapped by Spring MVC
```
