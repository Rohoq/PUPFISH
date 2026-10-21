import os
import re
import time
from datetime import datetime, timezone

import requests

from game_platform.models import GamePlatform
from games.models import Game
from platforms.models import Platform

_CACHED_TOKEN: dict[str, tuple[str, float]] = {}


def get_twitch_token(client_id: str, client_secret: str, use_cache: bool = True) -> str:
    cache_key = f"{client_id}:{client_secret}"
    now = time.time()
    if use_cache and cache_key in _CACHED_TOKEN:
        token, expires_at = _CACHED_TOKEN[cache_key]
        if now < expires_at - 60:
            return token

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

    token = data["access_token"]
    expires_in = data.get("expires_in", 3600)
    _CACHED_TOKEN[cache_key] = (token, now + float(expires_in))
    return token


def fetch_cover_by_id(token: str, client_id: str, cover_id: int) -> dict | None:
    url = "https://api.igdb.com/v4/covers"
    headers = {
        "Client-ID": client_id,
        "Authorization": f"Bearer {token}",
    }
    body = f"fields id, image_id, url; where id = {cover_id}; limit 1;"
    try:
        response = requests.post(url, headers=headers, data=body, timeout=10)
        data = response.json()
        if isinstance(data, list) and len(data) > 0:
            return data[0]
    except Exception:
        pass
    return None


def get_igdb_image_url(
    cover: dict | int | None,
    token: str | None = None,
    client_id: str | None = None,
    size: str = "cover_big",
) -> str | None:
    if not cover:
        return None

    if isinstance(cover, int):
        if not token or not client_id:
            return None
        cover = fetch_cover_by_id(token, client_id, cover)
        if not cover:
            return None

    if isinstance(cover, dict):
        image_id = cover.get("image_id")
        if image_id:
            return f"https://images.igdb.com/igdb/image/upload/t_{size}/{image_id}.jpg"
        url = cover.get("url")
        if url:
            if url.startswith("//"):
                url = f"https:{url}"
            if "/t_thumb/" in url and size != "thumb":
                url = url.replace("/t_thumb/", f"/t_{size}/")
            return url

    return None


def extract_steam_app_id(external_games: list[dict] | None) -> str | None:
    if not external_games or not isinstance(external_games, list):
        return None

    for ext in external_games:
        if not isinstance(ext, dict):
            continue

        url = ext.get("url") or ""
        uid = ext.get("uid")
        category = ext.get("category")
        source = ext.get("external_game_source")

        # Steam source or category is 1 in IGDB, or check url
        if category == 1 or source == 1 or "steampowered.com/app/" in url:
            if uid and str(uid).isdigit():
                return str(uid).strip()
            match = re.search(r"store\.steampowered\.com/app/(\d+)", url)
            if match:
                return match.group(1)

    return None


def fetch_game_metadata_from_igdb(
    game_name: str, size: str = "cover_big"
) -> dict[str, str | None]:
    client_id = os.getenv("CLIENT_ID")
    client_secret = os.getenv("CLIENT_SECRET")
    if not client_id or not client_secret:
        return {"cover_url": None, "steam_app_id": None}

    try:
        token = get_twitch_token(client_id, client_secret)
    except Exception:
        return {"cover_url": None, "steam_app_id": None}

    url = "https://api.igdb.com/v4/games"
    headers = {
        "Client-ID": client_id,
        "Authorization": f"Bearer {token}",
    }

    fields = (
        "id, name, cover.image_id, cover.url, "
        "external_games.category, external_games.external_game_source, "
        "external_games.uid, external_games.url"
    )

    safe_name = game_name.replace('"', '\\"')

    def _pick_best_match(items: list[dict]) -> dict | None:
        if not items:
            return None
        for it in items:
            if it.get("name", "").strip().lower() == game_name.strip().lower():
                return it
        return items[0]

    # 1. Search with game_type = 0 (primary base games)
    body_main = f'search "{safe_name}"; where game_type = 0; fields {fields}; limit 5;'
    try:
        response = requests.post(url, headers=headers, data=body_main, timeout=10)
        data = response.json()
        if isinstance(data, list) and len(data) > 0:
            item = _pick_best_match(data)
            if item:
                cover_url = get_igdb_image_url(
                    item.get("cover"), token=token, client_id=client_id, size=size
                )
                steam_app_id = extract_steam_app_id(item.get("external_games"))
                if cover_url or steam_app_id:
                    return {"cover_url": cover_url, "steam_app_id": steam_app_id}
    except Exception:
        pass

    # 2. Search without game_type constraint
    body = f'search "{safe_name}"; fields {fields}; limit 5;'
    try:
        response = requests.post(url, headers=headers, data=body, timeout=10)
        data = response.json()
        if isinstance(data, list) and len(data) > 0:
            item = _pick_best_match(data)
            if item:
                cover_url = get_igdb_image_url(
                    item.get("cover"), token=token, client_id=client_id, size=size
                )
                steam_app_id = extract_steam_app_id(item.get("external_games"))
                if cover_url or steam_app_id:
                    return {"cover_url": cover_url, "steam_app_id": steam_app_id}
    except Exception:
        pass

    # 3. Fallback: exact match in where clause
    body_fallback = f'where name = "{safe_name}"; fields {fields}; limit 1;'
    try:
        response = requests.post(url, headers=headers, data=body_fallback, timeout=10)
        data = response.json()
        if isinstance(data, list) and len(data) > 0:
            item = data[0]
            cover_url = get_igdb_image_url(
                item.get("cover"), token=token, client_id=client_id, size=size
            )
            steam_app_id = extract_steam_app_id(item.get("external_games"))
            return {"cover_url": cover_url, "steam_app_id": steam_app_id}
    except Exception:
        pass

    return {"cover_url": None, "steam_app_id": None}


def fetch_game_cover_from_igdb(game_name: str, size: str = "cover_big") -> str | None:
    metadata = fetch_game_metadata_from_igdb(game_name, size=size)
    return metadata.get("cover_url")


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
        platforms,
        cover.image_id,
        cover.url,
        external_games.category,
        external_games.external_game_source,
        external_games.uid,
        external_games.url;
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

            cover_data = item.get("cover")
            cover_url = (
                get_igdb_image_url(cover_data, token=token, client_id=client_id)
                if cover_data
                else None
            )
            steam_app_id = extract_steam_app_id(item.get("external_games"))

            game_obj, was_created = Game.objects.update_or_create(
                name=name,
                defaults={
                    "release_date": _parse_release_date(item.get("first_release_date")),
                    "rating": item.get("rating"),
                    "rating_count": item.get("rating_count", 0) or 0,
                    "aggregated_rating": item.get("aggregated_rating", 0) or 0,
                    "aggregated_rating_count": item.get("aggregated_rating_count", 0)
                    or 0,
                    "cover_url": cover_url,
                    "steam_app_id": steam_app_id,
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
