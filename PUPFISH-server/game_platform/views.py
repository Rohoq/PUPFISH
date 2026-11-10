from rest_framework import viewsets
from rest_framework.permissions import AllowAny
from .models import GamePlatform
from .serializers import GamePlatformSerializer


class GamePlatformViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = GamePlatformSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        qs = GamePlatform.objects.select_related("game", "platform").all()
        game_id = self.request.query_params.get("game")
        if game_id:
            qs = qs.filter(game_id=game_id)
        return qs
