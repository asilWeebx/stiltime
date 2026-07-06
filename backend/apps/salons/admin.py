from django.contrib import admin
from .models import Category, Salon, Branch, Service, SalonImage, WorkingHours, PromotionBanner, Coupon, FavoriteSalon

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'icon', 'order', 'is_active']
    list_editable = ['order', 'is_active']

@admin.register(Salon)
class SalonAdmin(admin.ModelAdmin):
    list_display = ['name', 'type', 'region', 'rating', 'is_verified', 'is_featured', 'is_active']
    list_filter = ['type', 'is_verified', 'is_featured', 'is_active']
    list_editable = ['is_verified', 'is_featured', 'is_active']
    search_fields = ['name', 'phone', 'address']
    prepopulated_fields = {'slug': ('name',)}

@admin.register(Service)
class ServiceAdmin(admin.ModelAdmin):
    list_display = ['name', 'salon', 'category', 'price', 'duration', 'is_active']
    list_filter = ['salon', 'category', 'is_active']

@admin.register(WorkingHours)
class WorkingHoursAdmin(admin.ModelAdmin):
    list_display = ['salon', 'barber', 'day_of_week', 'open_time', 'close_time', 'is_day_off']

@admin.register(PromotionBanner)
class PromotionBannerAdmin(admin.ModelAdmin):
    list_display = ['title', 'salon', 'order', 'is_active']
    list_editable = ['order', 'is_active']

@admin.register(Coupon)
class CouponAdmin(admin.ModelAdmin):
    list_display = ['code', 'salon', 'discount_type', 'discount_value', 'used_count', 'is_active']
    list_filter = ['is_active', 'discount_type']

admin.site.register(Branch)
admin.site.register(SalonImage)
admin.site.register(FavoriteSalon)
