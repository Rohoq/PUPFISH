import requests


STEAM_NEWS_URL = "https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/"


def fetch_game_news(steam_app_id: str, count: int = 10) -> list[dict]:
    if not steam_app_id.isdecimal():
        raise ValueError("Steam app ID must contain only digits.")

    response = requests.get(
        STEAM_NEWS_URL,
        params={"appid": steam_app_id, "count": count, "maxlength": 300},
        timeout=10,
    )
    response.raise_for_status()

    payload = response.json()
    app_news = payload.get("appnews") if isinstance(payload, dict) else None
    news_items = app_news.get("newsitems") if isinstance(app_news, dict) else None
    if not isinstance(news_items, list):
        raise ValueError("Steam returned an invalid news response.")

    return news_items
