from django.contrib import admin
from .models import Barber, BarberPortfolio, Vacation, FavoriteBarber, CustomerNote

@admin.register(Barber)
class BarberAdmin(admin.ModelAdmin):
    list_display = ['user', 'salon', 'status', 'rating', 'is_online', 'is_available', 'created_at']
    list_filter = ['status', 'is_online', 'is_available', 'salon']
    list_editable = ['status', 'is_online', 'is_available']
    search_fields = ['user__phone', 'user__full_name', 'specialization']
    actions = ['approve_barbers', 'reject_barbers']

    def approve_barbers(self, request, queryset):
        queryset.update(status='approved')
        self.message_user(request, f'{queryset.count()} sartarosh tasdiqlandi')
    approve_barbers.short_description = 'Tanlangan sartaroshlarni tasdiqlash'

    def reject_barbers(self, request, queryset):
        queryset.update(status='rejected')
        self.message_user(request, f'{queryset.count()} sartarosh rad etildi')
    reject_barbers.short_description = 'Tanlangan sartaroshlarni rad etish'

@admin.register(BarberPortfolio)
class PortfolioAdmin(admin.ModelAdmin):
    list_display = ['barber', 'caption', 'is_featured', 'likes', 'created_at']
    list_editable = ['is_featured']

@admin.register(CustomerNote)
class CustomerNoteAdmin(admin.ModelAdmin):
    list_display = ['barber', 'customer', 'is_vip', 'created_at']
    list_filter = ['is_vip']

admin.site.register(Vacation)
admin.site.register(FavoriteBarber)
