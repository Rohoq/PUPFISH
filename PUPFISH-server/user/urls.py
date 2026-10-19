from django.urls import path
from .views import UserLibraryView

urlpatterns = [
    path("<int:id>/library/", UserLibraryView.as_view()),
]
