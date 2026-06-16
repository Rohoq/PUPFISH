from django.db import models


class GameComment(models.Model):
    game = models.ForeignKey('games.Game', on_delete=models.CASCADE)
    user = models.ForeignKey('user.User', on_delete=models.CASCADE)
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.game.name} - {self.created_at}"