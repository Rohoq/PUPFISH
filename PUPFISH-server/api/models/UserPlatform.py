from django.db import models
from .User import User
from .Platform import Platform

class UserPlatform(models.Model):
    user = models.ForeignKey('api.User', on_delete=models.CASCADE)
    platform = models.ForeignKey('api.Platform', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.user.username} - {self.platform.name}"