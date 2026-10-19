from rest_framework import generics, filters
from rest_framework.permissions import AllowAny

from .models import Game
from .serializers import GameSerializer


class GameListView(generics.ListAPIView):
    queryset = Game.objects.all()
    serializer_class = GameSerializer
    permission_classes = [AllowAny]

    filter_backends = [filters.SearchFilter]
    search_fields = ["name"]
