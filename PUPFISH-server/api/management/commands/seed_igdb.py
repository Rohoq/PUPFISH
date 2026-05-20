from django.core.management.base import BaseCommand
from api.models import Game
import requests
import os
from datetime import datetime
import time


# ---------------------------
# Twitch token
# ---------------------------
def get_twitch_token(client_id, client_secret):
    url = "https://id.twitch.tv/oauth2/token"

    data = {
        "client_id": client_id,
        "client_secret": client_secret,
        "grant_type": "client_credentials",
    }

    r = requests.post(url, data=data)
    data = r.json()

    if "access_token" not in data:
        raise Exception(f"Twitch auth failed: {data}")

    return data["access_token"]


# ---------------------------
# IGDB fetch (single page)
# ---------------------------
def fetch_games(token, client_id, offset=0, limit=100):
    url = "https://api.igdb.com/v4/games"

    headers = {
        "Client-ID": client_id,
        "Authorization": f"Bearer {token}",
    }

    body = f"""
    fields name, first_release_date, cover.url;
    limit {limit};
    offset {offset};
    """

    r = requests.post(url, headers=headers, data=body)
    data = r.json()

    if isinstance(data, dict) and data.get("message"):
        raise Exception(f"IGDB error: {data}")

    return data


# ---------------------------
# Command
# ---------------------------
class Command(BaseCommand):
    help = "Seed many games from IGDB"

    def handle(self, *args, **kwargs):
        client_id = os.getenv("CLIENT_ID")
        client_secret = os.getenv("CLIENT_SECRET")

        if not client_id or not client_secret:
            raise Exception("Missing CLIENT_ID or CLIENT_SECRET")

        self.stdout.write("Pobieram token...")
        token = get_twitch_token(client_id, client_secret)

        all_games = []
        offset = 0
        limit = 100

        # 🔥 ile stron pobrać (np. 10 = ~1000 gier)
        pages = 10

        for i in range(pages):
            self.stdout.write(f"Pobieram offset {offset}...")

            games = fetch_games(token, client_id, offset, limit)

            if not games:
                break

            all_games.extend(games)

            offset += limit
            time.sleep(0.25)  # 🔥 ochrona przed rate limit

        created = 0
        updated = 0

        for g in all_games:
            name = g.get("name")
            if not name:
                continue

            ts = g.get("first_release_date")

            release_date = (
                datetime.utcfromtimestamp(ts).date()
                if ts
                else datetime(1970, 1, 1).date()
            )

            obj, was_created = Game.objects.update_or_create(
                name=name,
                defaults={
                    "release_date": release_date,
                }
            )

            if was_created:
                created += 1
            else:
                updated += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"DONE — total: {len(all_games)}, created: {created}, updated: {updated}"
            )
        )