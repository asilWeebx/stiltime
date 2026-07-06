from rest_framework import serializers
from .models import Notification, BroadcastNotification


class NotificationSerializer(serializers.ModelSerializer):
    notification_type = serializers.CharField(source='type', read_only=True)

    class Meta:
        model = Notification
        fields = ['id', 'title', 'body', 'type', 'notification_type', 'data', 'is_read', 'created_at']


class BroadcastNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = BroadcastNotification
        fields = ['id', 'title', 'body', 'target', 'image', 'data', 'scheduled_at']
        read_only_fields = ['sent_by', 'total_sent', 'is_sent', 'sent_at']
