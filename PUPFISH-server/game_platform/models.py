from django.db import models


class GamePlatform(models.Model):
    game = models.ForeignKey('games.Game', on_delete=models.CASCADE)
    platform = models.ForeignKey('platforms.Platform', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.game.name} - {self.platform.name}"