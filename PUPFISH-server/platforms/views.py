from rest_framework import viewsets
from rest_framework.permissions import AllowAny
from .models import Platform
from .serializers import PlatformSerializer


class PlatformViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Platform.objects.all()
    serializer_class = PlatformSerializer
    permission_classes = [AllowAny]
