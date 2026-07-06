from django.urls import path
from apps.users.views import (
    MeView, CustomerProfileView,
    RegionListView, DistrictListView, AdminUserListView,
)

urlpatterns = [
    path('me/', MeView.as_view(), name='user-me'),
    path('me/profile/', CustomerProfileView.as_view(), name='customer-profile'),
    path('regions/', RegionListView.as_view(), name='region-list'),
    path('districts/', DistrictListView.as_view(), name='district-list'),
    path('admin/list/', AdminUserListView.as_view(), name='admin-user-list'),
]
