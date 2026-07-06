from django.contrib import admin
from .models import Notification, BroadcastNotification

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'title', 'type', 'is_read', 'is_sent', 'created_at']
    list_filter = ['type', 'is_read', 'is_sent']
    search_fields = ['user__phone', 'title']

@admin.register(BroadcastNotification)
class BroadcastNotificationAdmin(admin.ModelAdmin):
    list_display = ['title', 'target', 'total_sent', 'is_sent', 'sent_by', 'created_at']
    list_filter = ['target', 'is_sent']
    readonly_fields = ['total_sent', 'is_sent', 'sent_at', 'sent_by']
