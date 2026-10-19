from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import UserPlatform
from .serializers import UserPlatformSerializer


class UserPlatformViewSet(viewsets.ModelViewSet):
    """
    CRUD powiązań zalogowanego użytkownika z platformami.
    """

    serializer_class = UserPlatformSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return UserPlatform.objects.filter(user=self.request.user).select_related(
            "platform"
        )

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
