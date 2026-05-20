import django.db.models as models
from .Game import Game
from .User import User

class Post(models.Model):
    title = models.CharField(max_length=255)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    game = models.ForeignKey('api.Game', on_delete=models.CASCADE)
    user = models.ForeignKey('api.User', on_delete=models.CASCADE)

    def __str__(self):
        return self.title
    