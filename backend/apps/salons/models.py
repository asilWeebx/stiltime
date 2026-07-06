from django.db import models
from django.conf import settings
from apps.users.models import Region, District


class Category(models.Model):
    GENDER_MALE = 'male'
    GENDER_FEMALE = 'female'
    GENDER_UNISEX = 'unisex'
    GENDER_CHOICES = [
        (GENDER_MALE, 'Erkaklar'),
        (GENDER_FEMALE, 'Ayollar'),
        (GENDER_UNISEX, 'Umumiy'),
    ]

    name = models.CharField(max_length=100)
    name_uz = models.CharField(max_length=100, blank=True)
    name_ru = models.CharField(max_length=100, blank=True)
    name_en = models.CharField(max_length=100, blank=True)
    icon = models.ImageField(upload_to='categories/icons/', null=True, blank=True)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, default=GENDER_UNISEX)
    order = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        verbose_name = 'Kategoriya'
        verbose_name_plural = 'Kategoriyalar'
        ordering = ['order', 'name']

    def __str__(self):
        return self.name


class Salon(models.Model):
    TYPE_BARBERSHOP = 'barbershop'
    TYPE_BEAUTY_SALON = 'beauty_salon'
    TYPE_CHOICES = [
        (TYPE_BARBERSHOP, 'Sartaroshxona'),
        (TYPE_BEAUTY_SALON, 'Go\'zallik saloni'),
    ]

    GENDER_MALE = 'male'
    GENDER_FEMALE = 'female'
    GENDER_UNISEX = 'unisex'
    GENDER_CHOICES = [
        (GENDER_MALE, 'Erkaklar uchun'),
        (GENDER_FEMALE, 'Ayollar uchun'),
        (GENDER_UNISEX, 'Hammasi uchun'),
    ]

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='owned_salons'
    )
    name = models.CharField(max_length=200)
    slug = models.SlugField(unique=True, blank=True)
    description = models.TextField(blank=True)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default=TYPE_BARBERSHOP)
    gender = models.CharField(max_length=10, choices=GENDER_CHOICES, default=GENDER_UNISEX)
    categories = models.ManyToManyField(Category, blank=True)
    logo = models.ImageField(upload_to='salons/logos/', null=True, blank=True)
    cover_image = models.ImageField(upload_to='salons/covers/', null=True, blank=True)
    phone = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    website = models.URLField(blank=True)
    instagram = models.CharField(max_length=100, blank=True)
    telegram = models.CharField(max_length=100, blank=True)
    region = models.ForeignKey(Region, on_delete=models.SET_NULL, null=True, blank=True)
    district = models.ForeignKey(District, on_delete=models.SET_NULL, null=True, blank=True)
    address = models.CharField(max_length=500, blank=True)
    latitude = models.DecimalField(max_digits=10, decimal_places=8, null=True, blank=True)
    longitude = models.DecimalField(max_digits=11, decimal_places=8, null=True, blank=True)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=0)
    total_reviews = models.IntegerField(default=0)
    total_bookings = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)
    accepts_online_booking = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'Salon'
        verbose_name_plural = 'Salonlar'
        ordering = ['-is_featured', '-rating']

    def __str__(self):
        return self.name

    @property
    def is_open(self):
        from django.utils import timezone
        now = timezone.localtime()
        day = now.weekday()
        hours = self.working_hours.filter(day_of_week=day, is_day_off=False).first()
        if not hours:
            return False
        return hours.open_time <= now.time() <= hours.close_time


class Branch(models.Model):
    salon = models.ForeignKey(Salon, on_delete=models.CASCADE, related_name='branches')
    name = models.CharField(max_length=200)
    phone = models.CharField(max_length=20, blank=True)
    region = models.ForeignKey(Region, on_delete=models.SET_NULL, null=True, blank=True)
    district = models.ForeignKey(District, on_delete=models.SET_NULL, null=True, blank=True)
    address = models.CharField(max_length=500, blank=True)
    latitude = models.DecimalField(max_digits=10, decimal_places=8, null=True, blank=True)
    longitude = models.DecimalField(max_digits=11, decimal_places=8, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    is_main = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Filial'
        verbose_name_plural = 'Filiallar'

    def __str__(self):
        return f"{self.salon.name} — {self.name}"


class Service(models.Model):
    salon = models.ForeignKey(Salon, on_delete=models.CASCADE, related_name='services')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True)
    name = models.CharField(max_length=200)
    name_uz = models.CharField(max_length=200, blank=True)
    name_ru = models.CharField(max_length=200, blank=True)
    name_en = models.CharField(max_length=200, blank=True)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=12, decimal_places=2)
    price_max = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    duration = models.IntegerField(help_text='Daqiqalarda')
    image = models.ImageField(upload_to='services/', null=True, blank=True)
    is_active = models.BooleanField(default=True)
    order = models.IntegerField(default=0)

    class Meta:
        verbose_name = 'Xizmat'
        verbose_name_plural = 'Xizmatlar'
        ordering = ['order', 'name']

    def __str__(self):
        return f"{self.salon.name} — {self.name} ({self.price} so'm)"


class SalonImage(models.Model):
    salon = models.ForeignKey(Salon, on_delete=models.CASCADE, related_name='images')
    image = models.ImageField(upload_to='salons/gallery/')
    caption = models.CharField(max_length=200, blank=True)
    order = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['order', '-created_at']


class WorkingHours(models.Model):
    DAY_CHOICES = [
        (0, 'Dushanba'), (1, 'Seshanba'), (2, 'Chorshanba'),
        (3, 'Payshanba'), (4, 'Juma'), (5, 'Shanba'), (6, 'Yakshanba'),
    ]
    salon = models.ForeignKey(Salon, on_delete=models.CASCADE, null=True, blank=True, related_name='working_hours')
    barber = models.ForeignKey('barbers.Barber', on_delete=models.CASCADE, null=True, blank=True, related_name='working_hours')
    day_of_week = models.IntegerField(choices=DAY_CHOICES)
    open_time = models.TimeField()
    close_time = models.TimeField()
    is_day_off = models.BooleanField(default=False)
    slot_duration = models.IntegerField(default=30, help_text='Slot daqiqalarda')
    break_start = models.TimeField(null=True, blank=True, verbose_name='Dam olish boshlanishi')
    break_end = models.TimeField(null=True, blank=True, verbose_name='Dam olish tugashi')

    class Meta:
        verbose_name = 'Ish vaqti'
        verbose_name_plural = 'Ish vaqtlari'
        unique_together = [['salon', 'barber', 'day_of_week']]

    def __str__(self):
        return f"{self.get_day_of_week_display()}: {self.open_time}–{self.close_time}"


class PromotionBanner(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    image = models.ImageField(upload_to='banners/')
    link = models.URLField(blank=True)
    salon = models.ForeignKey(Salon, on_delete=models.SET_NULL, null=True, blank=True)
    order = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    starts_at = models.DateTimeField(null=True, blank=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Banner'
        verbose_name_plural = 'Bannerlar'
        ordering = ['order', '-created_at']

    def __str__(self):
        return self.title


class Coupon(models.Model):
    TYPE_PERCENT = 'percent'
    TYPE_FIXED = 'fixed'
    TYPE_CHOICES = [(TYPE_PERCENT, 'Foizda'), (TYPE_FIXED, 'Belgilangan summa')]

    salon = models.ForeignKey(Salon, on_delete=models.CASCADE, null=True, blank=True, related_name='coupons')
    code = models.CharField(max_length=50, unique=True)
    discount_type = models.CharField(max_length=10, choices=TYPE_CHOICES, default=TYPE_PERCENT)
    discount_value = models.DecimalField(max_digits=10, decimal_places=2)
    min_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    max_uses = models.IntegerField(null=True, blank=True)
    used_count = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    starts_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Kupon'
        verbose_name_plural = 'Kuponlar'

    def __str__(self):
        return f"{self.code} — {self.discount_value}{'%' if self.discount_type == self.TYPE_PERCENT else ' so\'m'}"


class FavoriteSalon(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='favorite_salons')
    salon = models.ForeignKey(Salon, on_delete=models.CASCADE, related_name='favorited_by')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['user', 'salon']
        verbose_name = 'Sevimli salon'
        verbose_name_plural = 'Sevimli salonlar'
