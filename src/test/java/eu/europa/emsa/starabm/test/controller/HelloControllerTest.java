package eu.europa.emsa.starabm.test.controller;

import eu.europa.emsa.starabm.test.model.Greeting;
import eu.europa.emsa.starabm.test.service.HelloService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = HelloController.class)
class HelloControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private HelloService helloService;

    @Test
    @DisplayName("GET /api/hello returns default greeting when name not provided")
    void hello_defaultName() throws Exception {
        Mockito.when(helloService.greet("World")).thenReturn(new Greeting("Hello, World!"));

        mockMvc.perform(get("/api/hello").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().json("{\"message\":\"Hello, World!\"}"));
    }

    @Test
    @DisplayName("GET /api/hello?name=Alice returns greeting for Alice")
    void hello_withName() throws Exception {
        Mockito.when(helloService.greet("Alice")).thenReturn(new Greeting("Hello, Alice!"));

        mockMvc.perform(get("/api/hello").param("name", "Alice").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(content().json("{\"message\":\"Hello, Alice!\"}"));
    }
}

