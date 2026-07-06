from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.utils import timezone
from phonenumber_field.modelfields import PhoneNumberField
from .managers import UserManager


class Region(models.Model):
    name = models.CharField(max_length=100)
    name_uz = models.CharField(max_length=100, blank=True)
    name_ru = models.CharField(max_length=100, blank=True)
    name_en = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Viloyat'
        verbose_name_plural = 'Viloyatlar'
        ordering = ['name']

    def __str__(self):
        return self.name


class District(models.Model):
    region = models.ForeignKey(Region, on_delete=models.CASCADE, related_name='districts')
    name = models.CharField(max_length=100)
    name_uz = models.CharField(max_length=100, blank=True)
    name_ru = models.CharField(max_length=100, blank=True)
    name_en = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Tuman'
        verbose_name_plural = 'Tumanlar'
        ordering = ['name']

    def __str__(self):
        return f"{self.region.name} — {self.name}"


class User(AbstractBaseUser, PermissionsMixin):
    GENDER_MALE = 'male'
    GENDER_FEMALE = 'female'
    GENDER_CHOICES = [(GENDER_MALE, 'Erkak'), (GENDER_FEMALE, 'Ayol')]

    ROLE_CUSTOMER = 'customer'
    ROLE_BARBER = 'barber'
    ROLE_SALON_OWNER = 'salon_owner'
    ROLE_SUPERADMIN = 'superadmin'
    ROLE_CHOICES = [
        (ROLE_CUSTOMER, 'Mijoz'),
        (ROLE_BARBER, 'Sartarosh'),
        (ROLE_SALON_OWNER, 'Salon egasi'),
        (ROLE_SUPERADMIN, 'SuperAdmin'),
    ]

    LANG_UZ = 'uz'
    LANG_RU = 'ru'
    LANG_EN = 'en'
    LANG_CHOICES = [(LANG_UZ, "O'zbek"), (LANG_RU, 'Русский'), (LANG_EN, 'English')]

    phone = PhoneNumberField(unique=True, region='UZ')
    full_name = models.CharField(max_length=150, blank=True)
    email = models.EmailField(blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default=ROLE_CUSTOMER)
    language = models.CharField(max_length=5, choices=LANG_CHOICES, default=LANG_UZ)
    fcm_token = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)
    last_login = models.DateTimeField(null=True, blank=True)
    notification_booking = models.BooleanField(default=True)
    notification_promotions = models.BooleanField(default=True)
    notification_reminders = models.BooleanField(default=True)
    reminder_minutes = models.IntegerField(default=30, choices=[(15, '15 daqiqa'), (30, '30 daqiqa'), (45, '45 daqiqa'), (60, '1 soat')])

    objects = UserManager()

    USERNAME_FIELD = 'phone'
    REQUIRED_FIELDS = []

    class Meta:
        verbose_name = 'Foydalanuvchi'
        verbose_name_plural = 'Foydalanuvchilar'

    def __str__(self):
        return str(self.phone)

    @property
    def is_barber(self):
        return self.role == self.ROLE_BARBER

    @property
    def is_salon_owner(self):
        return self.role == self.ROLE_SALON_OWNER

    @property
    def is_superadmin(self):
        return self.role == self.ROLE_SUPERADMIN


class OTPCode(models.Model):
    phone = PhoneNumberField(region='UZ')
    code = models.CharField(max_length=10)
    attempts = models.IntegerField(default=0)
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

    class Meta:
        verbose_name = 'OTP Kod'
        verbose_name_plural = 'OTP Kodlar'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.phone} — {self.code}"

    @property
    def is_expired(self):
        return timezone.now() > self.expires_at

    @property
    def is_valid(self):
        return not self.is_used and not self.is_expired and self.attempts < 3


class CustomerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='customer_profile')
    loyalty_points = models.IntegerField(default=0)
    total_bookings = models.IntegerField(default=0)
    total_spent = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    referral_code = models.CharField(max_length=20, unique=True, blank=True)
    referred_by = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True)
    is_vip = models.BooleanField(default=False)
    vip_since = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Mijoz profili'
        verbose_name_plural = 'Mijoz profillari'

    def __str__(self):
        return f"{self.user} — {self.loyalty_points} ball"
