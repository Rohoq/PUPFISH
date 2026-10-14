from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticatedOrReadOnly
from .models import GamePlatform
from .serializers import GamePlatformSerializer


class GamePlatformViewSet(viewsets.ModelViewSet):
    queryset = GamePlatform.objects.select_related('game', 'platform').all()
    serializer_class = GamePlatformSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]