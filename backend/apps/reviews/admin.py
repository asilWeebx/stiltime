from django.contrib import admin
from .models import Review

@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['customer', 'barber', 'salon', 'rating', 'is_approved', 'created_at']
    list_filter = ['rating', 'is_approved', 'is_anonymous']
    list_editable = ['is_approved']
    search_fields = ['customer__phone', 'comment']
