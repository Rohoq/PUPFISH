from rest_framework import viewsets
from api.permissions import IsOwnerOrReadOnly
from .models import GameComment
from .serializers import GameCommentSerializer


class GameCommentViewSet(viewsets.ModelViewSet):
    serializer_class = GameCommentSerializer
    permission_classes = [IsOwnerOrReadOnly]

    def get_queryset(self):
        qs = GameComment.objects.select_related("user", "game").all()
        game_id = self.request.query_params.get("game")
        if game_id:
            qs = qs.filter(game_id=game_id)
        return qs

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
