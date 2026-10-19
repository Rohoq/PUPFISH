import os
import time
from datetime import datetime, timezone

import requests

from game_platform.models import GamePlatform
from games.models import Game
from platforms.models import Platform


def get_twitch_token(client_id: str, client_secret: str) -> str:
    response = requests.post(
        "https://id.twitch.tv/oauth2/token",
        data={
            "client_id": client_id,
            "client_secret": client_secret,
            "grant_type": "client_credentials",
        },
        timeout=15,
    )
    data = response.json()
    if "access_token" not in data:
        raise RuntimeError(f"Twitch auth failed: {data}")
    return data["access_token"]


def fetch_games_page(
    token: str, client_id: str, offset: int = 0, limit: int = 100
) -> list[dict]:
    url = "https://api.igdb.com/v4/games"
    headers = {
        "Client-ID": client_id,
        "Authorization": f"Bearer {token}",
    }
    body = f"""
    fields
        id,
        name,
        first_release_date,
        rating,
        rating_count,
        aggregated_rating,
        aggregated_rating_count,
        platforms;
    where game_type = 0;
    sort rating_count desc;
    limit {limit};
    offset {offset};
    """

    response = requests.post(url, headers=headers, data=body, timeout=20)
    data = response.json()

    if isinstance(data, dict) and data.get("message"):
        raise RuntimeError(f"IGDB error: {data}")

    return data if isinstance(data, list) else []


def fetch_platforms_page(
    token: str, client_id: str, offset: int = 0, limit: int = 100
) -> list[dict]:
    url = "https://api.igdb.com/v4/platforms"
    headers = {
        "Client-ID": client_id,
        "Authorization": f"Bearer {token}",
    }
    body = f"""
    fields
        id,
        name,
        slug,
        abbreviation,
        category;
    limit {limit};
    offset {offset};
    """

    response = requests.post(url, headers=headers, data=body, timeout=20)
    data = response.json()

    if isinstance(data, dict) and data.get("message"):
        raise RuntimeError(f"IGDB platform error: {data}")

    return data if isinstance(data, list) else []


def _parse_release_date(ts):
    if not ts:
        return datetime(1970, 1, 1).date()
    try:
        return datetime.fromtimestamp(ts, tz=timezone.utc).date()
    except (ValueError, OSError, OverflowError):
        return datetime(1970, 1, 1).date()


def _platform_lookup_from_igdb(platforms: list[dict]) -> dict[int, str]:
    lookup: dict[int, str] = {}
    for platform in platforms:
        platform_id = platform.get("id")
        name = platform.get("name")
        if platform_id is None or not name:
            continue
        lookup[int(platform_id)] = name.strip()
    return lookup


def _link_game_platforms(
    game_obj: Game,
    platform_ids: list[int | str] | None,
    platform_lookup: dict[int, str],
) -> int:
    if not platform_ids:
        return 0

    linked = 0
    for platform_id in platform_ids:
        try:
            platform_key = int(platform_id)
        except (TypeError, ValueError):
            continue

        platform_name = platform_lookup.get(platform_key)
        if not platform_name:
            continue

        platform_obj, _ = Platform.objects.get_or_create(name=platform_name)
        _, created = GamePlatform.objects.get_or_create(
            game=game_obj, platform=platform_obj
        )
        if created:
            linked += 1

    return linked


def sync_games(
    pages: int = 100, limit: int = 100, delay: float = 0.25, progress_callback=None
) -> dict:
    client_id = os.getenv("CLIENT_ID")
    client_secret = os.getenv("CLIENT_SECRET")

    if not client_id or not client_secret:
        raise ValueError("Missing CLIENT_ID or CLIENT_SECRET environment variables")

    token = get_twitch_token(client_id, client_secret)
    platform_lookup: dict[int, str] = {}
    platform_offset = 0

    for page in range(pages):
        if progress_callback:
            progress_callback(page + 1, pages, platform_offset)

        platform_batch = fetch_platforms_page(
            token, client_id, offset=platform_offset, limit=limit
        )
        if not platform_batch:
            break
        platform_lookup.update(_platform_lookup_from_igdb(platform_batch))
        platform_offset += limit
        time.sleep(delay)

    created = 0
    updated = 0
    total = 0
    offset = 0

    for page in range(pages):
        if progress_callback:
            progress_callback(page + 1, pages, offset)

        games_batch = fetch_games_page(token, client_id, offset=offset, limit=limit)
        if not games_batch:
            break

        for item in games_batch:
            name = item.get("name")
            if not name:
                continue

            game_obj, was_created = Game.objects.update_or_create(
                name=name,
                defaults={
                    "release_date": _parse_release_date(item.get("first_release_date")),
                    "rating": item.get("rating"),
                    "rating_count": item.get("rating_count", 0) or 0,
                    "aggregated_rating": item.get("aggregated_rating", 0) or 0,
                    "aggregated_rating_count": item.get("aggregated_rating_count", 0)
                    or 0,
                },
            )

            if was_created:
                created += 1
            else:
                updated += 1
            total += 1

            _link_game_platforms(game_obj, item.get("platforms"), platform_lookup)

        offset += limit
        time.sleep(delay)

    return {
        "total": total,
        "created": created,
        "updated": updated,
        "platforms": len(platform_lookup),
    }


def sync_game_platforms(
    pages: int = 10, limit: int = 100, delay: float = 0.25, progress_callback=None
) -> dict:
    """Sync game platforms using sync_games with a default of 10 pages."""
    return sync_games(
        pages=pages, limit=limit, delay=delay, progress_callback=progress_callback
    )
