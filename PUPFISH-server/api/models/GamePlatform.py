from django.db import models
from .Game import Game
from .Platform import Platform  

class GamePlatform(models.Model):
    game = models.ForeignKey('api.Game', on_delete=models.CASCADE)
    platform = models.ForeignKey('api.Platform', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.game.name} - {self.platform.name}"