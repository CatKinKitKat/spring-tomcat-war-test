# Use Apache Tomcat 9 with Java 11
FROM tomcat:9-jdk11

# Set environment variables for context path and WAR name
ARG WAR_FILE=test.war
ARG CONTEXT_PATH=test

# Copy the built WAR into Tomcat's webapps directory
# Expect the WAR at target/test.war after mvn package
COPY target/${WAR_FILE} /usr/local/tomcat/webapps/${CONTEXT_PATH}.war

# Expose Tomcat default port
EXPOSE 8080

# Healthcheck using wget (available in base image) to avoid curl dependency
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget --spider -q http://localhost:8080/ || exit 1

# Start Tomcat
CMD ["catalina.sh", "run"]
