from rest_framework import viewsets
from rest_framework.permissions import AllowAny
from .models import GamePlatform
from .serializers import GamePlatformSerializer


class GamePlatformViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = GamePlatform.objects.select_related("game", "platform").all()
    serializer_class = GamePlatformSerializer
    permission_classes = [AllowAny]
