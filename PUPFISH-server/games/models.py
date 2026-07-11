from django.db import models

class Game(models.Model):
    name = models.CharField(max_length=255)
    release_date = models.DateField()
    rating = models.FloatField(null=True, blank=True)
    rating_count = models.IntegerField(default=0)
    
    def __str__(self):
        return self.name
    
 