from django.urls import path
from .views import (
    CategoryListView, SalonListView, SalonDetailView,
    FavoriteSalonToggleView, FavoriteSalonListView,
    BannerListView, CouponValidateView,
    SalonReviewsView, SalonServicesView, SalonBarbersView,
    AdminSalonListView, AdminSalonDetailView,
    AdminCategoryView, AdminCategoryDetailView,
    AdminServiceView, AdminBannerView, AdminBannerDetailView,
    AdminWorkingHoursView, AdminSalonImagesView, AdminSalonImageDetailView,
)

urlpatterns = [
    path('categories/', CategoryListView.as_view(), name='category-list'),
    path('', SalonListView.as_view(), name='salon-list'),
    path('<int:pk>/', SalonDetailView.as_view(), name='salon-detail'),
    path('<int:pk>/favorite/', FavoriteSalonToggleView.as_view(), name='salon-favorite-toggle'),
    path('<int:pk>/reviews/', SalonReviewsView.as_view(), name='salon-reviews'),
    path('<int:pk>/services/', SalonServicesView.as_view(), name='salon-services'),
    path('<int:pk>/barbers/', SalonBarbersView.as_view(), name='salon-barbers'),
    path('favorites/', FavoriteSalonListView.as_view(), name='salon-favorites'),
    path('banners/', BannerListView.as_view(), name='banner-list'),
    path('coupons/validate/', CouponValidateView.as_view(), name='coupon-validate'),

    path('admin/salons/', AdminSalonListView.as_view(), name='admin-salon-list'),
    path('admin/salons/<int:pk>/', AdminSalonDetailView.as_view(), name='admin-salon-detail'),
    path('admin/salons/<int:pk>/working-hours/', AdminWorkingHoursView.as_view(), name='admin-salon-working-hours'),
    path('admin/salons/<int:pk>/images/', AdminSalonImagesView.as_view(), name='admin-salon-images'),
    path('admin/salons/<int:pk>/images/<int:img_id>/', AdminSalonImageDetailView.as_view(), name='admin-salon-image-detail'),
    path('admin/categories/', AdminCategoryView.as_view(), name='admin-category-list'),
    path('admin/categories/<int:pk>/', AdminCategoryDetailView.as_view(), name='admin-category-detail'),
    path('admin/services/', AdminServiceView.as_view(), name='admin-service-list'),
    path('admin/banners/', AdminBannerView.as_view(), name='admin-banner-list'),
    path('admin/banners/<int:pk>/', AdminBannerDetailView.as_view(), name='admin-banner-detail'),
]
