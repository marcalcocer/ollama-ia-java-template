import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public class SimpleOllamaClient {
    private final String baseUrl;
    private final HttpClient client;

    public SimpleOllamaClient(String host, int port) {
        this.baseUrl = "http://" + host + ":" + port;
        this.client = HttpClient.newHttpClient();
    }

    public String generate(String model, String prompt) throws Exception {
        String requestBody = String.format(
                "{\"model\": \"%s\", \"prompt\": \"%s\", \"stream\": false}",
                model, prompt.replace("\"", "\\\""));

        System.out.println("Sending request to: " + baseUrl + "/api/generate");
        System.out.println("Request Body: " + requestBody);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(baseUrl + "/api/generate"))
                .timeout(Duration.ofMinutes(2))
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();

        HttpResponse<String> response = client.send(
                request, HttpResponse.BodyHandlers.ofString());

        return response.body();
    }

    public static void main(String[] args) {
        try {
            long time = System.currentTimeMillis();
            String model = args.length > 0 ? args[0] : "llama3";

            SimpleOllamaClient client = new SimpleOllamaClient("localhost", 11434);

            // Test the connection
            String response = client.generate(model, "Hello, how are you?");
            System.out.println("Response: " + response);
            System.out.println("Time taken: " + (System.currentTimeMillis() - time) + "ms");

        } catch (Exception e) {
            System.out.println("Error: " + e);
            System.out.println("Make sure Ollama is running and the model is downloaded.");
            System.out.println("Run: ./scripts/up.sh && ./scripts/pull-model.sh");
        }
    }
}