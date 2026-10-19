from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import GamesLibrary
from .serializers import LibrariesSerializer


class LibrariesViewSet(viewsets.ModelViewSet):
    serializer_class = LibrariesSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return GamesLibrary.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
