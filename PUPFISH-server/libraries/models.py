from django.conf import settings
from django.db import models




class GamesLibrary(models.Model):

    STATUS_CHOICES = [
        ('playing', 'Playing'),
        ('completed', 'Completed'),
        ('dropped', 'Dropped'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE
    )

    game = models.ForeignKey(
        'games.Game',
        on_delete=models.CASCADE
    )

    rating = models.IntegerField(
        null=True,
        blank=True
    )

    state = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES
    )