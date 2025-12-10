package eu.europa.emsa.starabm.test.service;

import eu.europa.emsa.starabm.test.model.Greeting;
import org.springframework.stereotype.Service;

@Service
public class HelloService {
    public Greeting greet(String name) {
        return new Greeting("Hello, " + name + "!");
    }
}

