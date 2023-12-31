package org.example.ui.lambda;

import org.example.ui.testcontainer.AppContainer;
import org.example.ui.testcontainer.LocalstackRestApiCaller;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
public class LambdaIT {
    @Container
    private static final AppContainer app = new AppContainer();

    private final LocalstackRestApiCaller apiCaller = new LocalstackRestApiCaller(app);

    private static final String DB_CONTAINER_NAME = "localstack_db";

    @BeforeAll
    static void initializeAll() throws IOException {
        app.initialize();
        app.createApiForTestFunction();
        app.completeSetup();
    }

    @AfterEach
    void cleanupEach()
    {
        app.log();
    }

    @Test
    void testLambda() throws IOException, InterruptedException
    {
        var httpResponse = apiCaller.callTestFunction();

        assertThat(httpResponse.body()).isEqualTo("test");
    }
}
