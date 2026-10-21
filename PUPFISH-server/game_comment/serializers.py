from rest_framework import serializers
from .models import GameComment


class GameCommentSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)

    class Meta:
        model = GameComment
        fields = ["id", "game", "user", "username", "comment", "created_at"]
        read_only_fields = ["id", "user", "created_at"]
