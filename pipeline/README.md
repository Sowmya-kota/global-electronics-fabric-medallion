# Pipeline: pl_global_electronics_refresh

```
Bronze Ingest ──✓──> Silver Transform ──✓──> Gold Model ──✓──> Log Success
      │ ✗                  │ ✗                   │ ✗
Log Fail Bronze     Log Fail Silver       Log Fail Gold
```

| Activity | Type | Notebook | Retry | Depends on |
|---|---|---|---|---|
| Bronze Ingest | Notebook | nb_01_bronze_ingest | — | — |
| Silver Transform | Notebook | nb_02_silver_transform | 2 × 120 s | Bronze Ingest (success) |
| Gold Model | Notebook | nb_03_gold_model | 2 × 120 s | Silver Transform (success) |
| Log Success | Notebook | nb_04_log_run | 2 × 120 s | Gold Model (success) |
| Log Fail Bronze / Silver / Gold | Notebook | nb_04_log_run | 2 × 120 s | matching notebook (failure) |

## Base parameters passed to nb_04_log_run
| Parameter | Log Success | Log Fail <X> |
|---|---|---|
| pipeline_name | `pl_global_electronics_refresh` | `pl_global_electronics_refresh` |
| pipeline_run_id | `@pipeline().RunId` | `@pipeline().RunId` |
| status | `Succeeded` | `Failed` |
| failed_activity | — | `<X>` (e.g. `Silver Transform`) |
| error_message | — | `@activity('<X>').error.message` |

## Design decisions
- **One failure branch per notebook:** Fabric dependencies on one activity are AND-ed.
- **Failures stay visible:** nb_04 re-raises after logging, so the run status remains Failed.
- **Idempotent logging:** retried log steps don't duplicate rows.
- **Every notebook fails loudly:** Bronze reconciliation, the Silver DQ gate and the Gold quality gate all raise exceptions, so bad data never flows downstream.

## Tests performed
| Test | How | Result |
|---|---|---|
| Happy path | Normal run | All stages succeeded; etl_run_log: 62,884 rows at each layer, 0 rejects |
| Transient failure | Real capacity error (HTTP 430) on Gold | Retry succeeded; pipeline Succeeded |
| Data failure | Base parameter `max_reject_pct = -1` on Silver | Silver failed, Gold skipped, pipeline Failed, exactly 1 Failed row logged |

## Schedule
Not enabled: the source data is static and the Fabric trial capacity is limited. In production this would use the pipeline's built-in schedule (e.g. daily at 06:00), with the success/failure logging above providing monitoring.

## Export the pipeline definition
In Fabric: open the pipeline → **View** → **View JSON code** (`{}`), copy it, and save it here as `pl_global_electronics_refresh.json`.
