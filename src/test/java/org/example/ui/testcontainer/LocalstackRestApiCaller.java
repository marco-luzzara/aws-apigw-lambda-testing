package org.example.ui.testcontainer;

import com.google.gson.Gson;

import java.io.IOException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class LocalstackRestApiCaller {
    private final AppContainer appContainer;

    private static Gson gson = new Gson();
    private static final HttpClient HTTP_CLIENT = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.ALWAYS)
            .build();

    public LocalstackRestApiCaller(AppContainer appContainer) {
        this.appContainer = appContainer;
    }

    public HttpResponse<String> callTestFunction() throws IOException, InterruptedException {
        return HTTP_CLIENT.send(HttpRequest.newBuilder()
                        .GET()
                        .header("Content-Type", "application/json")
                        .timeout(Duration.ofSeconds(100))
                        .uri(this.appContainer.buildApiUrl("users"))
                        .build(), HttpResponse.BodyHandlers.ofString());
    }
}
