from django.db import models
from .User import User
from .Post import Post

class PostComment(models.Model):
    post = models.ForeignKey('api.Post', on_delete=models.CASCADE)
    user = models.ForeignKey('api.User', on_delete=models.CASCADE)
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.post.title} - {self.created_at}"