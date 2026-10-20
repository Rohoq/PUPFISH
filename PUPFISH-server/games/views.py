import requests
from django.http import HttpResponse, HttpResponseRedirect
from django.shortcuts import get_object_or_404
from rest_framework import filters, generics, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Game
from .serializers import GameSerializer
from .services.igdb import fetch_game_cover_from_igdb, fetch_game_metadata_from_igdb


class GameListView(generics.ListAPIView):
    queryset = Game.objects.all()
    serializer_class = GameSerializer
    permission_classes = [AllowAny]

    filter_backends = [filters.SearchFilter]
    search_fields = ["name"]


class GameThumbnailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk=None):
        size = request.query_params.get("size", "cover_big")
        game = None
        game_name = None

        if pk is not None:
            game = get_object_or_404(Game, pk=pk)
            game_name = game.name
        else:
            game_id = request.query_params.get("id")
            if game_id:
                game = get_object_or_404(Game, pk=game_id)
                game_name = game.name
            else:
                game_name = request.query_params.get("name")
                if not game_name:
                    return Response(
                        {"error": "Wymagany jest parametr 'pk', 'id' lub 'name'."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                game = Game.objects.filter(name__iexact=game_name).first()

        # 1. Sprawdź, czy miniatura jest już zapisana w bazie dla domyślnego rozmiaru
        cover_url = None
        if game and game.cover_url and size == "cover_big":
            cover_url = game.cover_url

        # 2. Jeśli brakuje miniatury lub steam_app_id, pobierz metadane z IGDB API
        if not cover_url or (game and not game.steam_app_id):
            metadata = fetch_game_metadata_from_igdb(game_name, size=size)
            if not cover_url and metadata.get("cover_url"):
                cover_url = metadata["cover_url"]

            if game:
                update_fields = []
                if cover_url and size == "cover_big" and not game.cover_url:
                    game.cover_url = cover_url
                    update_fields.append("cover_url")
                if metadata.get("steam_app_id") and not game.steam_app_id:
                    game.steam_app_id = metadata["steam_app_id"]
                    update_fields.append("steam_app_id")
                if update_fields:
                    game.save(update_fields=update_fields)

        if not cover_url:
            return Response(
                {"detail": f"Nie znaleziono miniaturki dla gry '{game_name}'."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # 3. Opcja format=json - zwrócenie adresu URL jako JSON
        if request.query_params.get("format") == "json":
            return Response(
                {
                    "thumbnail_url": cover_url,
                    "game": game_name,
                    "steam_app_id": game.steam_app_id if game else None,
                }
            )

        # 4. Opcja redirect=true - bezpośrednie przekierowanie HTTP 302 do pliku w CDN
        if request.query_params.get("redirect") in ("true", "1"):
            return HttpResponseRedirect(cover_url)

        # 5. Domyślnie: bezpośrednie serwowanie zawartości pliku obrazka (stream/proxy)
        try:
            img_res = requests.get(cover_url, timeout=10)
            if img_res.status_code == 200:
                content_type = img_res.headers.get("Content-Type", "image/jpeg")
                response = HttpResponse(img_res.content, content_type=content_type)
                response["Cache-Control"] = "public, max-age=86400"
                return response
            else:
                return HttpResponseRedirect(cover_url)
        except requests.RequestException:
            return HttpResponseRedirect(cover_url)
