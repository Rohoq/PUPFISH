from rest_framework import serializers
from .models import GamesLibrary


class LibrariesSerializer(serializers.ModelSerializer):
    game_name = serializers.CharField(source="game.name", read_only=True)

    game_release_date = serializers.DateField(
        source="game.release_date", read_only=True
    )

    game_cover_url = serializers.URLField(
        source="game.cover_url", read_only=True, allow_null=True
    )

    class Meta:
        model = GamesLibrary
        fields = [
            "id",
            "user",
            "game",
            "game_name",
            "game_release_date",
            "game_cover_url",
            "rating",
            "state",
        ]

        read_only_fields = [
            "id",
            "user",
            "game_name",
            "game_release_date",
            "game_cover_url",
        ]
