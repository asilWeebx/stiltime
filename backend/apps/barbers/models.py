from django.db import models
from django.conf import settings
from apps.salons.models import Salon, Branch, Service


class Barber(models.Model):
    STATUS_PENDING = 'pending'
    STATUS_APPROVED = 'approved'
    STATUS_REJECTED = 'rejected'
    STATUS_CHOICES = [
        (STATUS_PENDING, 'Kutilmoqda'),
        (STATUS_APPROVED, 'Tasdiqlangan'),
        (STATUS_REJECTED, 'Rad etilgan'),
    ]

    GENDER_MALE = 'male'
    GENDER_FEMALE = 'female'
    GENDER_CHOICES = [
        (GENDER_MALE, 'Erkak'),
        (GENDER_FEMALE, 'Ayol'),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='barber_profile'
    )
    salon = models.ForeignKey(Salon, on_delete=models.SET_NULL, null=True, blank=True, related_name='barbers')
    branch = models.ForeignKey(Branch, on_delete=models.SET_NULL, null=True, blank=True, related_name='barbers')
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, default=GENDER_MALE)
    bio = models.TextField(blank=True)
    specialization = models.CharField(max_length=200, blank=True)
    experience_years = models.IntegerField(default=0)
    services = models.ManyToManyField(Service, blank=True, related_name='barbers')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
    rejection_reason = models.TextField(blank=True)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    total_reviews = models.IntegerField(default=0)
    total_bookings = models.IntegerField(default=0)
    total_earned = models.DecimalField(max_digits=15, decimal_places=2, default=0)
    is_online = models.BooleanField(default=False)
    is_available = models.BooleanField(default=True)
    is_vacation = models.BooleanField(default=False)
    vacation_until = models.DateField(null=True, blank=True)
    cover_photo = models.ImageField(upload_to='barbers/covers/', null=True, blank=True)
    instagram = models.CharField(max_length=100, blank=True)
    telegram = models.CharField(max_length=100, blank=True)
    accepts_walk_in = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Sartarosh'
        verbose_name_plural = 'Sartaroshlar'
        ordering = ['-rating']

    def __str__(self):
        return f"{self.user.full_name or self.user.phone} ({self.salon})"

    @property
    def is_approved(self):
        return self.status == self.STATUS_APPROVED


class BarberPortfolio(models.Model):
    STATUS_PENDING  = 'pending'
    STATUS_APPROVED = 'approved'
    STATUS_REJECTED = 'rejected'
    STATUS_CHOICES  = [
        (STATUS_PENDING,  'Kutilmoqda'),
        (STATUS_APPROVED, 'Tasdiqlandi'),
        (STATUS_REJECTED, 'Rad etildi'),
    ]

    barber = models.ForeignKey(Barber, on_delete=models.CASCADE, related_name='portfolio')
    before_image = models.ImageField(upload_to='portfolios/before/', null=True, blank=True)
    after_image = models.ImageField(upload_to='portfolios/after/')
    caption = models.CharField(max_length=200, blank=True)
    service = models.ForeignKey(Service, on_delete=models.SET_NULL, null=True, blank=True)
    likes = models.IntegerField(default=0)
    is_featured = models.BooleanField(default=False)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default=STATUS_PENDING)
    rejection_reason = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Portfolio'
        verbose_name_plural = 'Portfoliolar'
        ordering = ['-is_featured', '-created_at']

    def __str__(self):
        return f"{self.barber} — {self.created_at.date()}"


class Vacation(models.Model):
    barber = models.ForeignKey(Barber, on_delete=models.CASCADE, related_name='vacations')
    start_date = models.DateField()
    end_date = models.DateField()
    reason = models.CharField(max_length=300, blank=True)
    is_approved = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Ta\'til'
        verbose_name_plural = 'Ta\'tillar'

    def __str__(self):
        return f"{self.barber} — {self.start_date} / {self.end_date}"


class FavoriteBarber(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='favorite_barbers')
    barber = models.ForeignKey(Barber, on_delete=models.CASCADE, related_name='favorited_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['user', 'barber']
        verbose_name = 'Sevimli sartarosh'
        verbose_name_plural = 'Sevimli sartaroshlar'


class CustomerNote(models.Model):
    barber = models.ForeignKey(Barber, on_delete=models.CASCADE, related_name='customer_notes')
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='barber_notes')
    note = models.TextField()
    is_vip = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Mijoz eslatmasi'
        verbose_name_plural = 'Mijoz eslatmalari'
        unique_together = ['barber', 'customer']

    def __str__(self):
        return f"{self.barber} → {self.customer}: {self.note[:50]}"
