from django.db import models
from .Game import Game
from .User import User

class GameComment(models.Model):
    game = models.ForeignKey('api.Game', on_delete=models.CASCADE)
    user = models.ForeignKey('api.User', on_delete=models.CASCADE)
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.game.name} - {self.created_at}"