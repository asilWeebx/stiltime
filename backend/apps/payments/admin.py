from django.contrib import admin
from .models import Payment, Transaction, SubscriptionPlan, Subscription

@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ['id', 'booking', 'customer', 'amount', 'method', 'status', 'paid_at']
    list_filter = ['status', 'method']
    search_fields = ['customer__phone', 'transaction_id']

@admin.register(SubscriptionPlan)
class SubscriptionPlanAdmin(admin.ModelAdmin):
    list_display = ['name', 'price_monthly', 'price_yearly', 'max_barbers', 'is_active']

@admin.register(Subscription)
class SubscriptionAdmin(admin.ModelAdmin):
    list_display = ['salon', 'plan', 'is_yearly', 'amount_paid', 'starts_at', 'expires_at', 'is_active']

admin.site.register(Transaction)
