import ballerina/http;
import ballerinax/redis;

const string SERVED_REQUESTS = "servedRequests";

configurable string redistHost = "localhost";
configurable int redistPort = 6379;
configurable decimal WINDOW_SIZE = 15;
configurable int MAX_REQUESTS = 5;

final redis:Client redisEp = check new (connection = {
    host: redistHost,
    port: redistPort
});

# RequestThrottlRedisInceptor is a request interceptor that can be used to throttle the incoming requests.
public isolated service class RequestThrottleRedisInterceptor {
    *http:RequestInterceptor;

    isolated resource function 'default [string... path](http:RequestContext ctx)
        returns http:TooManyRequests|http:NextService|error? {

        boolean allow = check allowRequest(redisEp);
        if allow {
            return ctx.next();
        } else {
            return http:TOO_MANY_REQUESTS;
        }
    }
}

