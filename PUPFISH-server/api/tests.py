import os
from unittest.mock import patch

from django.test import TestCase

from game_platform.models import GamePlatform
from games.models import Game
from games.services.igdb import (
    fetch_platforms_page,
    sync_game_platforms,
    extract_steam_app_id,
)
from platforms.models import Platform


class IgdbSyncTests(TestCase):
    @patch("games.services.igdb.requests.post")
    def test_fetch_platforms_page_returns_platforms(self, mock_post):
        mock_post.return_value.json.return_value = [
            {"id": 6, "name": "PC (Microsoft Windows)"},
            {"id": 48, "name": "PlayStation 4"},
        ]

        result = fetch_platforms_page("token", "client-id", offset=10, limit=25)

        self.assertEqual(len(result), 2)
        self.assertEqual(result[0]["name"], "PC (Microsoft Windows)")
        self.assertEqual(result[1]["name"], "PlayStation 4")

    @patch.dict(
        os.environ,
        {"CLIENT_ID": "client-id", "CLIENT_SECRET": "client-secret"},
        clear=False,
    )
    @patch("games.services.igdb.get_twitch_token", return_value="token")
    @patch(
        "games.services.igdb.fetch_games_page",
        return_value=[
            {"name": "Test Game", "platforms": [6, 48]},
        ],
    )
    @patch(
        "games.services.igdb.fetch_platforms_page",
        return_value=[
            {"id": 6, "name": "PC (Microsoft Windows)"},
            {"id": 48, "name": "PlayStation 4"},
        ],
    )
    def test_sync_game_platforms_creates_platform_links(
        self, mock_platforms, mock_games, mock_token
    ):
        result = sync_game_platforms(pages=1, limit=25, delay=0)

        self.assertEqual(result["total"], 1)
        self.assertEqual(Game.objects.filter(name="Test Game").count(), 1)
        self.assertEqual(
            Platform.objects.filter(name="PC (Microsoft Windows)").count(), 1
        )
        self.assertEqual(GamePlatform.objects.filter(game__name="Test Game").count(), 2)


class GameThumbnailTests(TestCase):
    def setUp(self):
        self.game = Game.objects.create(
            name="The Witcher 3",
            release_date="2015-05-19",
            cover_url="https://images.igdb.com/igdb/image/upload/t_cover_big/co1r7f.jpg",
        )
        self.game_without_cover = Game.objects.create(
            name="Cyberpunk 2077",
            release_date="2020-12-10",
        )

    @patch("games.views.requests.get")
    def test_get_thumbnail_by_pk_directly_serves_image(self, mock_requests_get):
        mock_requests_get.return_value.status_code = 200
        mock_requests_get.return_value.content = b"fake_image_bytes"
        mock_requests_get.return_value.headers = {"Content-Type": "image/jpeg"}

        response = self.client.get(f"/api/games/{self.game.pk}/thumbnail/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "image/jpeg")
        self.assertEqual(response.content, b"fake_image_bytes")
        mock_requests_get.assert_called_once_with(self.game.cover_url, timeout=10)

    def test_get_thumbnail_format_json(self):
        response = self.client.get(f"/api/games/{self.game.pk}/thumbnail/?format=json")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["thumbnail_url"], self.game.cover_url)

    def test_get_thumbnail_redirect(self):
        response = self.client.get(
            f"/api/games/{self.game.pk}/thumbnail/?redirect=true"
        )
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, self.game.cover_url)

    @patch("games.views.fetch_game_metadata_from_igdb")
    @patch("games.views.requests.get")
    def test_get_thumbnail_fetches_from_igdb_if_not_cached(
        self, mock_requests_get, mock_fetch_meta
    ):
        mock_fetch_meta.return_value = {
            "cover_url": "https://images.igdb.com/igdb/image/upload/t_cover_big/cyberpunk.jpg",
            "steam_app_id": "1091500",
        }
        mock_requests_get.return_value.status_code = 200
        mock_requests_get.return_value.content = b"cyberpunk_image_bytes"
        mock_requests_get.return_value.headers = {"Content-Type": "image/jpeg"}

        response = self.client.get(
            f"/api/games/{self.game_without_cover.pk}/thumbnail/"
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content, b"cyberpunk_image_bytes")
        mock_fetch_meta.assert_called_once_with("Cyberpunk 2077", size="cover_big")

        # Sprawdź, czy cover_url oraz steam_app_id zostały zaktualizowane w bazie
        self.game_without_cover.refresh_from_db()
        self.assertEqual(
            self.game_without_cover.cover_url,
            "https://images.igdb.com/igdb/image/upload/t_cover_big/cyberpunk.jpg",
        )
        self.assertEqual(self.game_without_cover.steam_app_id, "1091500")

    @patch("games.views.requests.get")
    def test_get_thumbnail_by_name_query(self, mock_requests_get):
        mock_requests_get.return_value.status_code = 200
        mock_requests_get.return_value.content = b"fake_image_bytes"
        mock_requests_get.return_value.headers = {"Content-Type": "image/jpeg"}

        response = self.client.get("/api/games/thumbnail/?name=The Witcher 3")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content, b"fake_image_bytes")

    def test_get_thumbnail_missing_param_returns_400(self):
        response = self.client.get("/api/games/thumbnail/")
        self.assertEqual(response.status_code, 400)

    @patch(
        "games.views.fetch_game_metadata_from_igdb",
        return_value={"cover_url": None, "steam_app_id": None},
    )
    def test_get_thumbnail_not_found_returns_404(self, mock_fetch_meta):
        response = self.client.get(
            f"/api/games/{self.game_without_cover.pk}/thumbnail/"
        )
        self.assertEqual(response.status_code, 404)


class SteamAppIdTests(TestCase):
    def test_extract_steam_app_id_from_uid(self):
        external_games = [
            {"category": 5, "uid": "123", "url": "https://gog.com"},
            {
                "category": 1,
                "uid": "292030",
                "url": "https://store.steampowered.com/app/292030",
            },
        ]
        steam_id = extract_steam_app_id(external_games)
        self.assertEqual(steam_id, "292030")

    def test_extract_steam_app_id_from_source(self):
        external_games = [
            {
                "external_game_source": 1,
                "uid": "1091500",
                "url": "https://store.steampowered.com/app/1091500",
            },
        ]
        steam_id = extract_steam_app_id(external_games)
        self.assertEqual(steam_id, "1091500")

    def test_extract_steam_app_id_from_url_fallback(self):
        external_games = [
            {
                "category": 99,
                "uid": None,
                "url": "https://store.steampowered.com/app/730/Counter_Strike_2",
            },
        ]
        steam_id = extract_steam_app_id(external_games)
        self.assertEqual(steam_id, "730")

    def test_extract_steam_app_id_none_when_no_steam(self):
        external_games = [
            {"category": 5, "uid": "gog123", "url": "https://gog.com"},
        ]
        self.assertIsNone(extract_steam_app_id(external_games))
        self.assertIsNone(extract_steam_app_id([]))
        self.assertIsNone(extract_steam_app_id(None))

    @patch.dict(
        os.environ,
        {"CLIENT_ID": "client-id", "CLIENT_SECRET": "client-secret"},
        clear=False,
    )
    @patch("games.services.igdb.get_twitch_token", return_value="token")
    @patch(
        "games.services.igdb.fetch_games_page",
        return_value=[
            {
                "name": "Witcher Test",
                "platforms": [],
                "cover": {"image_id": "co1r7f", "url": "//images.igdb.com/co1r7f.jpg"},
                "external_games": [
                    {
                        "category": 1,
                        "uid": "292030",
                        "url": "https://store.steampowered.com/app/292030",
                    }
                ],
            },
        ],
    )
    @patch("games.services.igdb.fetch_platforms_page", return_value=[])
    def test_sync_games_saves_steam_app_id_and_cover(
        self, mock_platforms, mock_games, mock_token
    ):
        sync_game_platforms(pages=1, limit=10, delay=0)

        game = Game.objects.get(name="Witcher Test")
        self.assertEqual(game.steam_app_id, "292030")
        self.assertEqual(
            game.cover_url,
            "https://images.igdb.com/igdb/image/upload/t_cover_big/co1r7f.jpg",
        )
