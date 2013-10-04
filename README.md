Streaming Sample
=====================

A basic sample application for EventSource interface for server-sent events.
Built using `faye-websockets` and `redis pub/sub`.

```shell
    cd streaming-sample
    bundle install
    foreman start
```

```shell

$ curl -i -H ACCEPT:text/event-stream localhost:9000

HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache, no-store
Connection: close

retry: 5000

:

:

:

```
