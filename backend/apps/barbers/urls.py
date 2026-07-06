from django.urls import path
from .views import (
    BarberListView, BarberDetailView, BarberPortfolioView, PortfolioFeedView,
    BarberReviewsView, BarberServicesView, BarberSlotsView,
    FavoriteBarberToggleView, FavoriteBarberListView, TopBarbersView,
    BarberRegisterView, BarberApplyView, BarberMeView,
    BarberPortfolioManageView, BarberPortfolioItemView,
    VacationView, CustomerNoteView, CustomerNoteDetailView,
    StatusToggleView, BarberDashboardView,
    BarberMeServicesView, BarberMeServiceDetailView, BarberScheduleView, BarberMeSlotsView, BarberSlotBlockView,
    BarberCustomerListView, BarberCustomerDetailView,
    AdminBarberListView, AdminBarberVerifyView, AdminBarberUpdateView, AdminBarberDeleteView,
    AdminBarberPortfolioView, AdminBarberPortfolioItemView, AdminPendingPortfolioView,
)

urlpatterns = [
    # Public barber endpoints
    path('', BarberListView.as_view(), name='barber-list'),
    path('top/', TopBarbersView.as_view(), name='top-barbers'),
    path('portfolio/', PortfolioFeedView.as_view(), name='portfolio-feed'),
    path('favorites/', FavoriteBarberListView.as_view(), name='barber-favorites'),
    path('register/', BarberRegisterView.as_view(), name='barber-register'),
    path('apply/', BarberApplyView.as_view(), name='barber-apply'),

    path('<int:pk>/', BarberDetailView.as_view(), name='barber-detail'),
    path('<int:pk>/portfolio/', BarberPortfolioView.as_view(), name='barber-portfolio'),
    path('<int:pk>/reviews/', BarberReviewsView.as_view(), name='barber-reviews'),
    path('<int:pk>/services/', BarberServicesView.as_view(), name='barber-services'),
    path('<int:pk>/slots/', BarberSlotsView.as_view(), name='barber-slots'),
    path('<int:pk>/favorite/', FavoriteBarberToggleView.as_view(), name='barber-favorite-toggle'),

    # Barber own panel
    path('me/', BarberMeView.as_view(), name='barber-me'),
    path('me/dashboard/', BarberDashboardView.as_view(), name='barber-dashboard'),
    path('me/services/', BarberMeServicesView.as_view(), name='barber-me-services'),
    path('me/services/<int:pk>/', BarberMeServiceDetailView.as_view(), name='barber-me-service-detail'),
    path('me/schedule/', BarberScheduleView.as_view(), name='barber-schedule'),
    path('me/portfolio/', BarberPortfolioManageView.as_view(), name='barber-portfolio-manage'),
    path('me/portfolio/<int:pk>/', BarberPortfolioItemView.as_view(), name='barber-portfolio-item'),
    path('me/vacation/', VacationView.as_view(), name='barber-vacation'),
    path('me/status/', StatusToggleView.as_view(), name='barber-status-toggle'),
    path('me/slots/', BarberMeSlotsView.as_view(), name='barber-me-slots'),
    path('me/blocks/', BarberSlotBlockView.as_view(), name='barber-slot-block'),
    path('me/customers/', BarberCustomerListView.as_view(), name='barber-customers'),
    path('me/customers/<int:pk>/', BarberCustomerDetailView.as_view(), name='barber-customer-detail'),
    path('me/notes/', CustomerNoteView.as_view(), name='customer-notes'),
    path('me/notes/<int:pk>/', CustomerNoteDetailView.as_view(), name='customer-note-detail'),

    # Admin
    path('admin/list/', AdminBarberListView.as_view(), name='admin-barber-list'),
    path('admin/<int:pk>/verify/', AdminBarberVerifyView.as_view(), name='admin-barber-verify'),
    path('admin/<int:pk>/update/', AdminBarberUpdateView.as_view(), name='admin-barber-update'),
    path('admin/<int:pk>/delete/', AdminBarberDeleteView.as_view(), name='admin-barber-delete'),
    path('admin/portfolio/pending/', AdminPendingPortfolioView.as_view(), name='admin-portfolio-pending'),
    path('admin/<int:pk>/portfolio/', AdminBarberPortfolioView.as_view(), name='admin-barber-portfolio'),
    path('admin/<int:pk>/portfolio/<int:item_id>/', AdminBarberPortfolioItemView.as_view(), name='admin-barber-portfolio-item'),
]
