from django.contrib import admin
from games.models import Game
from platforms.models import Platform
from game_platform.models import GamePlatform
from game_comment.models import GameComment
from posts.models import Post
from post_comment.models import PostComment
from libraries.models import GamesLibrary
from user.models import User
from user_platform.models import UserPlatform


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
