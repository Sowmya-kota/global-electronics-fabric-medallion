# Lessons Learned

### 1. Spark 4 charset restriction (Bronze)
**Error:** `INVALID_PARAMETER_VALUE.CHARSET ... expects one of iso-8859-1, us-ascii, utf-16 ... but got windows-1252`.
**Tempting fix rejected:** switching to ISO-8859-1 would have "worked" while silently corrupting 74 characters (e.g. *Miloš Hooijenga*).
**Fix:** `spark.conf.set("spark.sql.legacy.javaCharsets", "true")`, then verified the accented names after loading.
**Takeaway:** check the data before choosing a workaround; a fix that doesn't throw an error can still be wrong.

### 2. Lakehouse SQL analytics endpoint is read-only
`CREATE TABLE` / `INSERT` fail there. Tables are written by Spark (notebooks), Dataflows or pipelines; the endpoint is for querying (T-SQL) and needs no Spark session.

### 3. Spark capacity limits (HTTP 430 TooManyRequestsForCapacity)
Interactive notebook sessions and each pipeline notebook activity all need their own Spark session. On a trial capacity, a new session was refused while others were still releasing.
**Fixes:** stop idle sessions; retry policies (2 × 120 s) on pipeline activities. Verified: a Gold attempt failed with 430 and the retry succeeded.
**Option:** high-concurrency session sharing for pipeline notebooks.

### 4. The failure logger can fail too
The failure-log activity hit the same capacity limit, so the first failures were never recorded. The pipeline run history was the backstop.
**Fix:** retries on the log activities, plus **idempotent** logging (skip the write if this run's outcome is already logged), so 3 attempts produce 1 row.

### 5. Pipeline dependencies are AND-ed
Three failure arrows into one shared "log failure" activity means it only runs if *all three* fail, which is impossible here. Hence one failure branch per notebook.

### 6. Expressions vs. literals in pipeline parameters
In dynamic content, a value starting with `@` is evaluated as an expression (`@pipeline().RunId`). Literal values like `Succeeded` must not start with `@`. `@activity('X').error.message` only works when X is upstream of the current activity, so draw the dependency first.

### 7. Retries are blind
Retries re-run deterministic failures (e.g. a DQ gate breach) as well as transient ones, which wastes capacity. Next improvement: signal data-quality failures separately so only infrastructure errors are retried.

### 8. Test failure paths, not just success
The real data produced 0 DQ rejects, which proves nothing about the rules. Synthetic bad rows (Silver) and parameter-driven fault injection (pipeline) proved that rejects, gates, logging and failure status all behave as designed.
