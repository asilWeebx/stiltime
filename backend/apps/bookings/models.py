from django.db import models
from django.conf import settings
from apps.salons.models import Salon, Branch, Service
from apps.barbers.models import Barber


class Booking(models.Model):
    STATUS_PENDING = 'pending'
    STATUS_CONFIRMED = 'confirmed'
    STATUS_IN_PROGRESS = 'in_progress'
    STATUS_COMPLETED = 'completed'
    STATUS_CANCELLED = 'cancelled'
    STATUS_NO_SHOW = 'no_show'
    STATUS_CHOICES = [
        (STATUS_PENDING, 'Kutilmoqda'),
        (STATUS_CONFIRMED, 'Tasdiqlangan'),
        (STATUS_IN_PROGRESS, 'Davom etmoqda'),
        (STATUS_COMPLETED, 'Bajarildi'),
        (STATUS_CANCELLED, 'Bekor qilindi'),
        (STATUS_NO_SHOW, 'Kelmadi'),
    ]

    SOURCE_APP = 'app'
    SOURCE_TELEGRAM = 'telegram'
    SOURCE_WALK_IN = 'walk_in'
    SOURCE_CHOICES = [
        (SOURCE_APP, 'Ilova'),
        (SOURCE_TELEGRAM, 'Telegram'),
        (SOURCE_WALK_IN, 'Bevosita'),
    ]

    customer = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='bookings', null=True, blank=True
    )
    barber = models.ForeignKey(Barber, on_delete=models.CASCADE, related_name='bookings')
    salon = models.ForeignKey(Salon, on_delete=models.CASCADE, related_name='bookings')
    branch = models.ForeignKey(Branch, on_delete=models.SET_NULL, null=True, blank=True)
    services = models.ManyToManyField(Service, related_name='bookings')
    date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    total_duration = models.IntegerField(help_text='Daqiqalarda')
    total_price = models.DecimalField(max_digits=12, decimal_places=2)
    discount_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    final_price = models.DecimalField(max_digits=12, decimal_places=2)
    coupon = models.ForeignKey('salons.Coupon', on_delete=models.SET_NULL, null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
    source = models.CharField(max_length=20, choices=SOURCE_CHOICES, default=SOURCE_APP)
    notes = models.TextField(blank=True)
    cancellation_reason = models.TextField(blank=True)
    reminder_sent = models.BooleanField(default=False)
    reminder_15m_sent = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Bron'
        verbose_name_plural = 'Bronlar'
        ordering = ['-date', '-start_time']

    def __str__(self):
        return f"#{self.pk} — {self.customer or 'Walk-in'} → {self.barber} ({self.date} {self.start_time})"


class WalkInBooking(models.Model):
    STATUS_CONFIRMED   = 'confirmed'
    STATUS_IN_PROGRESS = 'in_progress'
    STATUS_COMPLETED   = 'completed'
    STATUS_CANCELLED   = 'cancelled'
    STATUS_CHOICES = [
        (STATUS_CONFIRMED,   'Tasdiqlangan'),
        (STATUS_IN_PROGRESS, 'Jarayonda'),
        (STATUS_COMPLETED,   'Bajarildi'),
        (STATUS_CANCELLED,   'Bekor'),
    ]

    barber = models.ForeignKey(Barber, on_delete=models.CASCADE, related_name='walk_in_bookings')
    customer_name = models.CharField(max_length=150)
    customer_phone = models.CharField(max_length=20, blank=True)
    services = models.ManyToManyField(Service, blank=True)
    date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    total_price = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_CONFIRMED)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Bevosita bron'
        verbose_name_plural = 'Bevosita bronlar'

    def __str__(self):
        return f"{self.customer_name} → {self.barber} ({self.date} {self.start_time})"


class TimeSlot(models.Model):
    barber = models.ForeignKey(Barber, on_delete=models.CASCADE, related_name='time_slots')
    date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_available = models.BooleanField(default=True)
    is_blocked = models.BooleanField(default=False)
    block_reason = models.CharField(max_length=200, blank=True)

    class Meta:
        verbose_name = 'Vaqt sloti'
        verbose_name_plural = 'Vaqt slotlari'
        unique_together = ['barber', 'date', 'start_time']
        ordering = ['date', 'start_time']

    def __str__(self):
        return f"{self.barber} — {self.date} {self.start_time}"
