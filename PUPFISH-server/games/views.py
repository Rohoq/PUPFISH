from rest_framework import generics
from rest_framework.permissions import AllowAny, IsAuthenticated
from .models import Game
from .serializers import GameSerializer

class GameListView(generics.ListAPIView):
    queryset = Game.objects.all()
    serializer_class = GameSerializer
    permission_classes = [AllowAny]