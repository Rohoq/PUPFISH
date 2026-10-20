"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""

from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from user.views import RegisterView
from games.views import GameListView, GameThumbnailView
from libraries.views import LibrariesViewSet
from platforms.views import PlatformViewSet
from game_platform.views import GamePlatformViewSet
from game_comment.views import GameCommentViewSet
from posts.views import PostViewSet
from post_comment.views import PostCommentViewSet
from user_platform.views import UserPlatformViewSet

router = DefaultRouter()
router.register(r"library", LibrariesViewSet, basename="library")
router.register(r"platforms", PlatformViewSet, basename="platform")
router.register(r"game-platforms", GamePlatformViewSet, basename="game-platform")
router.register(r"game-comments", GameCommentViewSet, basename="game-comment")
router.register(r"posts", PostViewSet, basename="post")
router.register(r"post-comments", PostCommentViewSet, basename="post-comment")
router.register(r"user-platforms", UserPlatformViewSet, basename="user-platform")

urlpatterns = [
    path("admin/", admin.site.urls),
    # Auth & JWT
    path("api/register/", RegisterView.as_view(), name="register"),
    path("api/login/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("api/token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    # Games (ListAPIView & Thumbnail)
    path("api/games/", GameListView.as_view(), name="game-list"),
    path(
        "api/games/<int:pk>/thumbnail/",
        GameThumbnailView.as_view(),
        name="game-thumbnail",
    ),
    path(
        "api/games/thumbnail/",
        GameThumbnailView.as_view(),
        name="game-thumbnail-query",
    ),
    # Relacje specyficzne użytkownika
    path("api/users/", include("user.urls")),
    # Wszystkie zasoby DRF Routera
    path("api/", include(router.urls)),
]
