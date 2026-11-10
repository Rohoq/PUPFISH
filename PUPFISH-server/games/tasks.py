from celery import shared_task

from games.services.igdb import sync_games


@shared_task
def sync_games_from_igdb():
    return sync_games()
