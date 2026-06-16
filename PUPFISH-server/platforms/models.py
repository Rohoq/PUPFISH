from django.db import models

class Platform(models.Model):
    name = models.CharField(max_length=255)
    
    def __str__(self):
        return self.name