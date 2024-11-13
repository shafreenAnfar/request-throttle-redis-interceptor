import ballerina/time;
import ballerinax/redis;
import ballerina/lang.'decimal as dec;

isolated function allowRequest(redis:Client redisEp) returns boolean|error {
    final decimal currentTime = time:monotonicNow();

    decimal[] lastServedRequests = check getLastFewRequestWithOffset(MAX_REQUESTS, redisEp);
    decimal[] requestsWithinWindow = removeOldRequests(lastServedRequests, currentTime);
    boolean windowNotFull = isWindowNotFull(requestsWithinWindow);
    
    if windowNotFull {
        _ = check redisEp->lPush(SERVED_REQUESTS, [currentTime.toString()]);
        _ = check redisEp->lTrim(SERVED_REQUESTS, 0, MAX_REQUESTS);
    }
    return windowNotFull;
}

isolated function getLastFewRequestWithOffset(int offset, redis:Client redisEp) returns decimal[]|error {
    decimal[] lastServedRequests = [];
    string[]|redis:Error lRange = redisEp->lRange(SERVED_REQUESTS, 0, MAX_REQUESTS);
    if lRange is string[] {
        foreach var item in lRange {
            lastServedRequests.push(check dec:fromString(item));
            _ = lastServedRequests.reverse();
        }
    }
    return lastServedRequests;
}

isolated function removeOldRequests(decimal[] lastServedRequests, decimal currentTime) returns decimal[] {
    while (lastServedRequests.length() != 0) {
        decimal reqTimeGap = currentTime - lastServedRequests[lastServedRequests.length() - 1];
        if reqTimeGap > WINDOW_SIZE {
            _ = lastServedRequests.pop();
        } else {
            break;
        }
    }
    return lastServedRequests;
}

isolated function isWindowNotFull(decimal[] requestsWithinWindow) returns boolean {
    return requestsWithinWindow.length() < MAX_REQUESTS;
}