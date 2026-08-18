from rest_framework import generics
from rest_framework.permissions import AllowAny
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer
from rest_framework.generics import ListAPIView
from libraries.models import GamesLibrary
from libraries.serializers import LibrariesSerializer

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = [AllowAny]
    serializer_class = RegisterSerializer

class UserLibraryView(ListAPIView):
    serializer_class = LibrariesSerializer

    def get_queryset(self):
        return GamesLibrary.objects.filter(
            user_id=self.kwargs["id"]
        )