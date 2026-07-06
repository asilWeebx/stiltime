from rest_framework import serializers
from .models import (
    Category, Salon, Branch, Service, SalonImage,
    WorkingHours, PromotionBanner, Coupon, FavoriteSalon
)


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'name_uz', 'name_ru', 'name_en', 'icon', 'gender', 'order']


class ServiceSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_icon = serializers.ImageField(source='category.icon', read_only=True)
    category_gender = serializers.CharField(source='category.gender', read_only=True)

    class Meta:
        model = Service
        fields = ['id', 'salon', 'category', 'category_name', 'category_icon', 'category_gender',
                  'name', 'name_uz', 'name_ru', 'description', 'price', 'price_max',
                  'duration', 'image', 'is_active', 'order']


class WorkingHoursSerializer(serializers.ModelSerializer):
    day_name = serializers.CharField(source='get_day_of_week_display', read_only=True)

    class Meta:
        model = WorkingHours
        fields = ['id', 'day_of_week', 'day_name', 'open_time', 'close_time', 'is_day_off', 'slot_duration']


class SalonImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = SalonImage
        fields = ['id', 'image', 'caption', 'order']


class SalonListSerializer(serializers.ModelSerializer):
    category_names = serializers.SerializerMethodField()
    category_name = serializers.SerializerMethodField()
    district_name = serializers.CharField(source='district.name', read_only=True)
    region_name = serializers.CharField(source='region.name', read_only=True)
    is_favorite = serializers.SerializerMethodField()
    is_open = serializers.SerializerMethodField()
    review_count = serializers.IntegerField(source='total_reviews', read_only=True)

    class Meta:
        model = Salon
        fields = [
            'id', 'name', 'type', 'gender', 'logo', 'cover_image', 'phone',
            'address', 'region_name', 'district_name',
            'rating', 'total_reviews', 'review_count', 'total_bookings',
            'category_names', 'category_name', 'is_verified', 'is_featured',
            'accepts_online_booking', 'is_favorite', 'is_open',
        ]

    def get_category_names(self, obj):
        return [c.name for c in obj.categories.all()]

    def get_category_name(self, obj):
        first = obj.categories.first()
        return first.name if first else None

    def get_is_favorite(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return FavoriteSalon.objects.filter(user=request.user, salon=obj).exists()
        return False

    def get_is_open(self, obj):
        try:
            return obj.is_open
        except Exception:
            return True


class SalonDetailSerializer(serializers.ModelSerializer):
    services = ServiceSerializer(many=True, read_only=True)
    working_hours = WorkingHoursSerializer(many=True, read_only=True)
    images = SalonImageSerializer(many=True, read_only=True)
    categories = CategorySerializer(many=True, read_only=True)
    is_favorite = serializers.SerializerMethodField()
    is_open = serializers.SerializerMethodField()

    class Meta:
        model = Salon
        fields = '__all__'

    def get_is_favorite(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return FavoriteSalon.objects.filter(user=request.user, salon=obj).exists()
        return False

    def get_is_open(self, obj):
        try:
            return obj.is_open
        except Exception:
            return None


class BranchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Branch
        fields = '__all__'


class PromotionBannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = PromotionBanner
        fields = ['id', 'title', 'description', 'image', 'link', 'salon', 'order']


class CouponSerializer(serializers.ModelSerializer):
    class Meta:
        model = Coupon
        fields = ['id', 'code', 'discount_type', 'discount_value', 'min_amount', 'expires_at']


class CouponValidateSerializer(serializers.Serializer):
    code = serializers.CharField()
    salon_id = serializers.IntegerField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
