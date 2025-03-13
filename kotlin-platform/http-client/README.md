to use `implementation io.github.antonmarin:http-client:latest`

```kotlin
ApacheHttpClientBuilder()
    .withTimeout("2S") // Duration.ofSeconds(2)
    .withRetries(2, Const, "50ms")
    .withCBAfter(5, "10s")
    .build()
```


Facade over ApacheHttpClient to add common distributed systems features.

1. Timeouts will be never lost
2. Retries. Idempotent/non-idempotent cares. Max count. Delays
3. CircuitBreaker
4. Logging
5. Tracing
6. Metrics
7. FineTuning of base client
