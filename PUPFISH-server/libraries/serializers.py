from rest_framework import serializers
from .models import  GamesLibrary

class LibrariesSerializer(serializers.ModelSerializer):
    class Meta:
        model = GamesLibrary
        fields = '__all__'