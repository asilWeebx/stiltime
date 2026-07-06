from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from apps.salons.models import Salon
from apps.barbers.models import Barber
from apps.bookings.models import Booking


class Review(models.Model):
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reviews')
    booking = models.OneToOneField(Booking, on_delete=models.CASCADE, related_name='review', null=True, blank=True)
    salon = models.ForeignKey(Salon, on_delete=models.CASCADE, null=True, blank=True, related_name='reviews')
    barber = models.ForeignKey(Barber, on_delete=models.CASCADE, null=True, blank=True, related_name='reviews')
    rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.TextField(blank=True)
    is_anonymous = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=True)
    likes = models.IntegerField(default=0)
    reply = models.TextField(blank=True)
    replied_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Sharh'
        verbose_name_plural = 'Sharhlar'
        ordering = ['-created_at']

    def __str__(self):
        target = self.barber or self.salon
        return f"{self.customer} → {target}: {self.rating}⭐"
