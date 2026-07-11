from games.models import Game
from datetime import datetime
import requests
import os
import time


def sync_games():

    client_id = os.getenv("CLIENT_ID")
    client_secret = os.getenv("CLIENT_SECRET")

    # token Twitch
    token_response = requests.post(
        "https://id.twitch.tv/oauth2/token",
        data={
            "client_id": client_id,
            "client_secret": client_secret,
            "grant_type": "client_credentials",
        }
    )
    print(token_response.json())


    token = token_response.json()["access_token"]
    
    headers = {
        "Client-ID": client_id,
        "Authorization": f"Bearer {token}",
    }

    total = 0

    limit = 500
    pages = 20  # 20 * 500 = około 10000 gier
    offset = 0


    for i in range(pages):

        response = requests.post(
            "https://api.igdb.com/v4/games",
            headers=headers,
            data=f"""
                fields name, first_release_date, rating, rating_count;
                where 
                    game_type = 0;
                    
                sort rating_count desc;
                limit {limit};
                offset {offset};
            """
        )

        games = response.json()
        print(games)
        print(f"Pobrano stronę {i+1}: {len(games)} gier z IGDB")

        if not games:
            break


        for game in games:

            timestamp = game.get("first_release_date")

            if timestamp:
                try:
                    release_date = datetime.fromtimestamp(timestamp).date()
                except (OSError, ValueError, OverflowError):
                    release_date = datetime(1970, 1, 1).date()
            else:
                release_date = datetime(1970, 1, 1).date()


            Game.objects.update_or_create(
                name=game["name"],
                defaults={
                    "release_date": release_date,
                    "rating": game.get("rating"),
                    "rating_count": game.get("rating_count", 0),
                }
            )

            total += 1
            
           


        offset += limit

        time.sleep(0.01)


    return total