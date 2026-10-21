from rest_framework import serializers
from .models import PostComment


class PostCommentSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source="user.username", read_only=True)

    class Meta:
        model = PostComment
        fields = ["id", "post", "user", "username", "comment", "created_at"]
        read_only_fields = ["id", "user", "created_at"]
