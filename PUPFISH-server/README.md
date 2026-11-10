# Backend

## Daily IGDB sync and Steam news

Celery Beat synchronizes the game catalog from IGDB daily at 02:00 UTC. Steam news is fetched on demand from Steam's API and is not stored in the database.

The public news endpoint is `GET /api/games/<game_id>/news/?count=10`. The optional `count` parameter accepts values from 1 to 100.

Run Redis and set `CELERY_BROKER_URL`, `CLIENT_ID`, and `CLIENT_SECRET`. From this directory, run one Celery worker and one Beat process:

```shell
celery -A config worker --loglevel=INFO
celery -A config beat --loglevel=INFO
```

Run only one Celery Beat instance per environment to avoid queueing duplicate sync tasks.
