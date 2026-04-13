from collections import defaultdict, deque
from threading import Lock
from time import time

from fastapi import HTTPException, Request, status

_WINDOW_SECONDS = 60
_MAX_REQUESTS = 10
_BUCKETS: dict[str, deque[float]] = defaultdict(deque)
_LOCK = Lock()


def enforce_auth_rate_limit(request: Request) -> None:
    client_host = request.client.host if request.client else "unknown"
    key = "{}:{}".format(request.url.path, client_host)
    now = time()

    with _LOCK:
        bucket = _BUCKETS[key]
        while bucket and now - bucket[0] > _WINDOW_SECONDS:
            bucket.popleft()

        if len(bucket) >= _MAX_REQUESTS:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many auth attempts. Please try again shortly.",
            )

        bucket.append(now)
