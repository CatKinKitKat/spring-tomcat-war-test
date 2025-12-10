package eu.europa.emsa.starabm.test.controller;

import eu.europa.emsa.starabm.test.model.Greeting;
import eu.europa.emsa.starabm.test.service.HelloService;
import lombok.AllArgsConstructor;
import lombok.Getter;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(path = "/api/hello")
@AllArgsConstructor
public class HelloController {

    @Getter
    private final HelloService helloService;

    @GetMapping(produces = MediaType.APPLICATION_JSON_VALUE)
    public Greeting hello(@RequestParam(name = "name", defaultValue = "World") String name) {
        return helloService.greet(name);
    }
}

