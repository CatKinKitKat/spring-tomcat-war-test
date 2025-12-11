# Aplicação Spring Boot em WAR num Tomcat autónomo

Este projeto demonstra como empacotar uma aplicação Spring Boot como WAR e implantá-la num servidor Apache Tomcat autónomo (incluindo via Docker).

## Visão geral: JAR vs WAR no Spring Boot
- JAR: Empacotamento comum do Spring Boot que incorpora o Tomcat (ou outro servidor). Executa com `java -jar`. Simples e autocontido.
- WAR: Empacota a aplicação como um arquivo web e implanta num Tomcat externo/autónomo. Útil quando é necessário usar um Tomcat existente ou um servidor de aplicações partilhado.

Diferenças principais ao construir um WAR:
- A classe principal estende `SpringBootServletInitializer` para suportar a inicialização no contentor de servlets.
- A aplicação é empacotada com `war` em `pom.xml` e exclui o Tomcat incorporado do runtime.
- O WAR é implantado sob um caminho de contexto web, derivado do nome do WAR (por exemplo, `test.war` -> `/test`).

Neste repositório, o ponto de entrada é `eu.europa.emsa.starabm.test.Application`, que estende `SpringBootServletInitializer`.

## Como arranca no Tomcat
- O Tomcat analisa o WAR, carrega o `SpringBootServletInitializer` do Spring e inicializa o ApplicationContext do Spring.
- A aplicação corre por trás da pilha HTTP do Tomcat; os seus endpoints ficam acessíveis em `http://localhost:8080/<contexto>/...`.
- O caminho de contexto é tipicamente o nome do WAR sem a extensão `.war` (configurável via Tomcat ou localização de cópia).

## Implantação com Tomcat via Docker
O `Dockerfile` incluído segue o padrão: copiar o WAR construído para a pasta `webapps` do Tomcat.

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

Depois de construir e executar o contentor, a aplicação fica disponível em:
- `http://localhost:8080/test/api/hello`

## Scripts de reimplantação
Use os scripts fornecidos para reconstruir o WAR, reconstruir a imagem Docker e reiniciar o contentor Tomcat.

- Bash (Linux/macOS, WSL, Git Bash):
  ```bash
  chmod +x scripts/redeploy.sh
  ./scripts/redeploy.sh
  # Substituições opcionais via env: IMAGE_NAME, CONTAINER_NAME, PORT, WAR_FILE, CONTEXT_PATH
  ```

- PowerShell (Windows):
  ```powershell
  .\scripts\redeploy.ps1
  # Parâmetros opcionais
  .\scripts\redeploy.ps1 -ImageName tomcat9:latest -ContainerName tomcat -Port 8080 -WarFile test.war -ContextPath test
  ```

Ambos os scripts fazem:
1) `mvn clean package` para construir o WAR
2) Parar/remover o contentor `tomcat` existente
3) `docker build` com argumentos WAR/contexto
4) `docker run` na porta 8080 com política de reinício

## Configuração em implantações WAR
- Propriedades: O ficheiro principal é `src/main/resources/application.properties`. A aplicação também tenta carregar `/configuration/application.properties` do sistema de ficheiros (opcional), permitindo configuração externa.
- Caminho de contexto: O Tomcat define o contexto pelo nome do WAR (`test.war` => `/test`). Ajuste alterando o nome do WAR ou a configuração do Tomcat.
- Variáveis de ambiente: O Spring Boot pode ler propriedades via variáveis de ambiente (por exemplo, `SPRING_DATASOURCE_URL`). Conveniente em contentores.

### Segurança
Por padrão, o Spring Security protege os endpoints. Este projeto inclui um `SecurityConfig` que:
- Permite todas as requisições (`anyRequest().permitAll()`)
- Desativa CSRF, formulário de login e HTTP Basic, para que não apareça página de login

Ajuste a configuração para proteger caminhos específicos em produção.

### Considerações de base de dados
Se a aplicação precisar de base de dados:
- Defina propriedades reais `spring.datasource.*` (URL, utilizador, palavra-passe, driver) e inclua a dependência do driver JDBC.
- Por exemplo, PostgreSQL:
  ```properties
  spring.datasource.url=jdbc:postgresql://db-host:5432/yourdb
  spring.datasource.username=youruser
  spring.datasource.password=yourpass
  spring.datasource.driver-class-name=org.postgresql.Driver
  ```
- Inclua o driver em `pom.xml`:
  ```xml
  <dependency>
    <groupId>org.postgresql</groupId>
    <artifactId>postgresql</artifactId>
  </dependency>
  ```

Se quiser que a aplicação arranque sem base de dados, este projeto desativa a auto-configuração JDBC via:
```
spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
```
Remova essa linha quando fornecer um datasource real e quiser que Liquibase/JPA inicializem.

## Testes locais
- Browser:
  - Saudação por defeito: `http://localhost:8080/test/api/hello`
  - Saudação com nome: `http://localhost:8080/test/api/hello?name=Alice`
- PowerShell:
  ```powershell
  Invoke-WebRequest -UseBasicParsing http://localhost:8080/test/api/hello
  Invoke-WebRequest -UseBasicParsing "http://localhost:8080/test/api/hello?name=Alice"
  ```

## Resolução de problemas
- Página de login aparece: Certifique-se de que o `SecurityConfig` está ativo e que reconstruiu/implantou o WAR.
- 404 Not Found: Verifique o caminho de contexto (`/test` por defeito) e que o WAR foi copiado para o Tomcat como `test.war`.
- Erros de classe de driver de BD: Forneça um `spring.datasource.driver-class-name` válido e inclua a dependência do driver, ou mantenha `DataSourceAutoConfiguration` excluída para execuções sem BD.
- Saúde do contentor em arranque/falha: Aguarde o arranque ou verifique logs com `docker logs tomcat`.

## Porque usar implantações WAR
- Requisitos organizacionais para implantar num Tomcat partilhado.
- Operações preferem gestão e monitorização centralizadas do servidor.
- Permite múltiplas aplicações num só Tomcat (com caminhos de contexto distintos).

## Referências
- Spring Boot: empacotamento para produção e contentores de servlets
- Tomcat: implantação de aplicações web e caminhos de contexto

## Diagrama de arquitetura (ASCII)

```
+---------------------------+                          +-----------------------------+
|         Cliente           |  pedidos/respostas HTTP  |        Host / Docker        |
| (Browser, curl, Postman)  | <----------------------> |  corre servidor Apache Tomcat|
+---------------------------+                          +-----------------------------+
                                                         |
                                                         | arranca
                                                         v
                                               +---------------------+
                                               |      Tomcat         |
                                               |  (Autónomo 9.x)     |
                                               +----------+----------+
                                                          |
                                                          | implanta WAR como contexto
                                                          v
                                       +------------------+------------------+
                                       |  Spring Boot WAR (test.war)         |
                                       |  Caminho de contexto: /test         |
                                       |  Controllers, Services, Config      |
                                       +------------------+------------------+
                                                          ^
                                                          |
                                   ex.: /test/api/hello   |  mapeado pelo Spring MVC
```

