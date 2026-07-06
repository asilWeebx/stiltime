from django.urls import path
from .views import AdminDashboardView, BarberAnalyticsView

urlpatterns = [
    path('admin/dashboard/', AdminDashboardView.as_view(), name='admin-dashboard'),
    path('barber/', BarberAnalyticsView.as_view(), name='barber-analytics'),
]
