from django.db import models
from django.conf import settings
from apps.bookings.models import Booking


class Payment(models.Model):
    METHOD_CASH = 'cash'
    METHOD_CARD = 'card'
    METHOD_CLICK = 'click'
    METHOD_PAYME = 'payme'
    METHOD_UZUM = 'uzum'
    METHOD_CHOICES = [
        (METHOD_CASH, 'Naqd'),
        (METHOD_CARD, 'Karta'),
        (METHOD_CLICK, 'Click'),
        (METHOD_PAYME, 'Payme'),
        (METHOD_UZUM, 'Uzum Bank'),
    ]

    STATUS_PENDING = 'pending'
    STATUS_PAID = 'paid'
    STATUS_FAILED = 'failed'
    STATUS_REFUNDED = 'refunded'
    STATUS_CHOICES = [
        (STATUS_PENDING, 'Kutilmoqda'),
        (STATUS_PAID, 'To\'landi'),
        (STATUS_FAILED, 'Xatolik'),
        (STATUS_REFUNDED, 'Qaytarildi'),
    ]

    booking = models.OneToOneField(Booking, on_delete=models.CASCADE, related_name='payment')
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    method = models.CharField(max_length=20, choices=METHOD_CHOICES, default=METHOD_CASH)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
    transaction_id = models.CharField(max_length=200, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'To\'lov'
        verbose_name_plural = 'To\'lovlar'
        ordering = ['-created_at']

    def __str__(self):
        return f"#{self.pk} — {self.booking} — {self.amount} so'm ({self.get_status_display()})"


class Transaction(models.Model):
    payment = models.ForeignKey(Payment, on_delete=models.CASCADE, related_name='transactions')
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    note = models.CharField(max_length=300, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Tranzaksiya'
        verbose_name_plural = 'Tranzaksiyalar'


class SubscriptionPlan(models.Model):
    name = models.CharField(max_length=100)
    price_monthly = models.DecimalField(max_digits=12, decimal_places=2)
    price_yearly = models.DecimalField(max_digits=12, decimal_places=2)
    max_barbers = models.IntegerField(default=5)
    max_branches = models.IntegerField(default=1)
    features = models.JSONField(default=list)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Obuna rejasi'
        verbose_name_plural = 'Obuna rejalari'

    def __str__(self):
        return self.name


class Subscription(models.Model):
    salon = models.ForeignKey('salons.Salon', on_delete=models.CASCADE, related_name='subscriptions')
    plan = models.ForeignKey(SubscriptionPlan, on_delete=models.PROTECT)
    is_yearly = models.BooleanField(default=False)
    amount_paid = models.DecimalField(max_digits=12, decimal_places=2)
    starts_at = models.DateTimeField()
    expires_at = models.DateTimeField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Obuna'
        verbose_name_plural = 'Obunalar'

    def __str__(self):
        return f"{self.salon} — {self.plan}"
