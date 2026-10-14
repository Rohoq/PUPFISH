from rest_framework import serializers
from .models import GamePlatform


class GamePlatformSerializer(serializers.ModelSerializer):
    game_name = serializers.CharField(source='game.name', read_only=True)
    platform_name = serializers.CharField(source='platform.name', read_only=True)

    class Meta:
        model = GamePlatform
        fields = ['id', 'game', 'game_name', 'platform', 'platform_name']