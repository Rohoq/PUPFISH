import os
from unittest.mock import patch

from django.test import TestCase

from game_platform.models import GamePlatform
from games.models import Game
from games.services.igdb import fetch_platforms_page, sync_game_platforms
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
