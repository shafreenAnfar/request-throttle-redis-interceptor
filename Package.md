# Request Throttling Interceptor with Redis

This Ballerina interceptor throttles HTTP requests based on a sliding window algorithm using Redis as the backing store. The interceptor limits the number of requests a client can send within a specific time window.

## Configuration

The interceptor supports the following configurable values:

- `redistHost`: The Redis server's host (default: `localhost`).
- `redistPort`: The Redis server's port (default: `6379`).
- `WINDOW_SIZE`: The size of the time window in seconds (default: `15` seconds).
- `MAX_REQUESTS`: The maximum number of requests allowed within the time window (default: `5` requests).

## Request Throttler Interceptor

The `RequestThrottlerRedisInceptor` service class implements request interception to limit incoming HTTP requests using Redis.

- **Redis Client**: A Redis client (`redis:Client`) is initialized in the `init` function to communicate with the Redis server.
- **Resource Function**: 
  - The `default` resource is triggered for any incoming requests.
  - It checks whether the request should be allowed or throttled by calling the `allowRequest()` function.
  - If the request is allowed, it proceeds to the next service using `ctx.next()`.
  - If the request exceeds the rate limit, a `HTTP 429 Too Many Requests` response is returned.

### Request Validation Logic

The core logic to determine whether a request is allowed is implemented in the `allowRequest` function, which follows these steps:

1. **Get Last Served Requests**: 
   - Fetches the most recent request timestamps from Redis using `getLastFewRequestWithOffset()`.
   
2. **Filter Old Requests**: 
   - Removes requests that are older than the configured `WINDOW_SIZE` using `removeOldRequests()`.
   
3. **Check Window Status**: 
   - Determines if the sliding window has room for more requests using `isWindowNotFull()`.

4. **Push Current Request**: 
   - If the window is not full, the current request timestamp is added to the Redis list.