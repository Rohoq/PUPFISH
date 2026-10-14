from rest_framework import serializers
from .models import UserPlatform


class UserPlatformSerializer(serializers.ModelSerializer):
    platform_name = serializers.CharField(source='platform.name', read_only=True)

    class Meta:
        model = UserPlatform
        fields = ['id', 'user', 'platform', 'platform_name']
        read_only_fields = ['id', 'user', 'platform_name']