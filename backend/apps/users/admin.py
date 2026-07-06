from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User, OTPCode, CustomerProfile, Region, District


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['phone', 'full_name', 'role', 'is_verified', 'is_active', 'date_joined']
    list_filter = ['role', 'is_verified', 'is_active', 'gender']
    search_fields = ['phone', 'full_name', 'email']
    ordering = ['-date_joined']
    fieldsets = (
        (None, {'fields': ('phone', 'password')}),
        ('Shaxsiy ma\'lumotlar', {'fields': ('full_name', 'email', 'avatar', 'gender', 'date_of_birth')}),
        ('Sozlamalar', {'fields': ('role', 'language', 'fcm_token', 'reminder_minutes')}),
        ('Huquqlar', {'fields': ('is_active', 'is_staff', 'is_superuser', 'is_verified', 'groups', 'user_permissions')}),
        ('Bildirishnomalar', {'fields': ('notification_booking', 'notification_promotions', 'notification_reminders')}),
    )
    add_fieldsets = (
        (None, {'classes': ('wide',), 'fields': ('phone', 'password1', 'password2', 'role')}),
    )


@admin.register(OTPCode)
class OTPCodeAdmin(admin.ModelAdmin):
    list_display = ['phone', 'code', 'is_used', 'attempts', 'created_at', 'expires_at']
    list_filter = ['is_used']
    readonly_fields = ['created_at']


@admin.register(CustomerProfile)
class CustomerProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'loyalty_points', 'total_bookings', 'total_spent', 'is_vip']
    list_filter = ['is_vip']
    search_fields = ['user__phone', 'user__full_name', 'referral_code']


@admin.register(Region)
class RegionAdmin(admin.ModelAdmin):
    list_display = ['name', 'is_active']


@admin.register(District)
class DistrictAdmin(admin.ModelAdmin):
    list_display = ['name', 'region', 'is_active']
    list_filter = ['region', 'is_active']
