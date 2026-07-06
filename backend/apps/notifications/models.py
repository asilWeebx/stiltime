from django.db import models
from django.conf import settings


class Notification(models.Model):
    TYPE_BOOKING = 'booking'
    TYPE_REMINDER = 'reminder'
    TYPE_PROMOTION = 'promotion'
    TYPE_SYSTEM = 'system'
    TYPE_REVIEW = 'review'
    TYPE_CHOICES = [
        (TYPE_BOOKING, 'Bron'),
        (TYPE_REMINDER, 'Eslatma'),
        (TYPE_PROMOTION, 'Aksiya'),
        (TYPE_SYSTEM, 'Tizim'),
        (TYPE_REVIEW, 'Sharh'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=200)
    title_uz = models.CharField(max_length=200, blank=True)
    title_ru = models.CharField(max_length=200, blank=True)
    body = models.TextField()
    body_uz = models.TextField(blank=True)
    body_ru = models.TextField(blank=True)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default=TYPE_SYSTEM)
    data = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False)
    is_sent = models.BooleanField(default=False)
    sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Bildirishnoma'
        verbose_name_plural = 'Bildirishnomalar'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user} — {self.title}"


class BroadcastNotification(models.Model):
    TARGET_ALL = 'all'
    TARGET_CUSTOMERS = 'customers'
    TARGET_BARBERS = 'barbers'
    TARGET_CHOICES = [
        (TARGET_ALL, 'Hammasi'),
        (TARGET_CUSTOMERS, 'Mijozlar'),
        (TARGET_BARBERS, 'Sartaroshlar'),
    ]

    title = models.CharField(max_length=200)
    body = models.TextField()
    target = models.CharField(max_length=20, choices=TARGET_CHOICES, default=TARGET_ALL)
    image = models.ImageField(upload_to='notifications/', null=True, blank=True)
    data = models.JSONField(default=dict, blank=True)
    sent_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True)
    total_sent = models.IntegerField(default=0)
    is_sent = models.BooleanField(default=False)
    scheduled_at = models.DateTimeField(null=True, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Ommaviy bildirishnoma'
        verbose_name_plural = 'Ommaviy bildirishnomalar'

    def __str__(self):
        return f"{self.title} → {self.get_target_display()}"
