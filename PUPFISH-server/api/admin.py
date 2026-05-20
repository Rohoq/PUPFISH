from django.contrib import admin
from .models import Game, Platform, User, GameComment, UserPlatform, GamePlatform, GamesLibrary, Post, PostComment

admin.site.register(Game)
admin.site.register(Platform)
admin.site.register(User)
admin.site.register(GameComment)
admin.site.register(UserPlatform)
admin.site.register(GamePlatform)
admin.site.register(GamesLibrary)
admin.site.register(Post)
admin.site.register(PostComment)


# Register your models here.
