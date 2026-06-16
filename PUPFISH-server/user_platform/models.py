from django.db import models


class UserPlatform(models.Model):
    user = models.ForeignKey('user.User', on_delete=models.CASCADE)
    platform = models.ForeignKey('platforms.Platform', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.user.username} - {self.platform.name}"