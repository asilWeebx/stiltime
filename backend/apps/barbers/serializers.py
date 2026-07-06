from rest_framework import serializers
from .models import Barber, BarberPortfolio, Vacation, FavoriteBarber, CustomerNote
from apps.salons.serializers import ServiceSerializer, WorkingHoursSerializer
from apps.users.serializers import UserSerializer


class BarberListSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='user.full_name', read_only=True)
    phone = serializers.CharField(source='user.phone', read_only=True)
    avatar = serializers.SerializerMethodField()
    salon_name = serializers.CharField(source='salon.name', read_only=True)
    is_favorite = serializers.SerializerMethodField()

    class Meta:
        model = Barber
        fields = [
            'id', 'full_name', 'phone', 'avatar', 'salon', 'salon_name',
            'bio', 'specialization', 'experience_years', 'gender',
            'rating', 'total_reviews', 'total_bookings',
            'is_online', 'is_available', 'status',
            'is_favorite',
        ]

    def get_avatar(self, obj):
        req = self.context.get('request')
        if obj.user.avatar and req:
            return req.build_absolute_uri(obj.user.avatar.url)
        return None

    def get_is_favorite(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return FavoriteBarber.objects.filter(user=request.user, barber=obj).exists()
        return False


class BarberDetailSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    full_name = serializers.CharField(source='user.full_name', read_only=True)
    avatar = serializers.SerializerMethodField()
    services = ServiceSerializer(many=True, read_only=True)
    working_hours = WorkingHoursSerializer(many=True, read_only=True)
    salon_name = serializers.CharField(source='salon.name', read_only=True)
    salon_id = serializers.IntegerField(source='salon.id', read_only=True)
    salon_cover = serializers.SerializerMethodField()
    salon_address = serializers.CharField(source='salon.address', read_only=True)
    review_count = serializers.IntegerField(source='total_reviews', read_only=True)
    is_favorite = serializers.SerializerMethodField()
    portfolio_count = serializers.SerializerMethodField()
    total_bookings = serializers.SerializerMethodField()

    cover_photo = serializers.SerializerMethodField()

    class Meta:
        model = Barber
        fields = [
            'id', 'user', 'full_name', 'avatar', 'cover_photo',
            'salon', 'salon_id', 'salon_name', 'salon_cover', 'salon_address',
            'bio', 'specialization', 'experience_years', 'gender', 'instagram', 'telegram',
            'services', 'working_hours',
            'rating', 'total_reviews', 'review_count', 'total_bookings', 'total_earned',
            'is_online', 'is_available', 'is_vacation', 'status',
            'accepts_walk_in', 'is_favorite', 'portfolio_count',
            'created_at',
        ]

    def get_avatar(self, obj):
        req = self.context.get('request')
        if obj.user.avatar and req:
            return req.build_absolute_uri(obj.user.avatar.url)
        return None

    def get_cover_photo(self, obj):
        req = self.context.get('request')
        if obj.cover_photo and req:
            return req.build_absolute_uri(obj.cover_photo.url)
        return None

    def get_salon_cover(self, obj):
        req = self.context.get('request')
        if obj.salon and obj.salon.cover_image and req:
            return req.build_absolute_uri(obj.salon.cover_image.url)
        return None

    def get_is_favorite(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return FavoriteBarber.objects.filter(user=request.user, barber=obj).exists()
        return False

    def get_portfolio_count(self, obj):
        return obj.portfolio.count()

    def get_total_bookings(self, obj):
        from apps.bookings.models import Booking
        return Booking.objects.filter(barber=obj).count()


class BarberUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Barber
        fields = [
            'bio', 'specialization', 'experience_years',
            'gender', 'cover_photo', 'accepts_walk_in',
            'instagram', 'telegram',
        ]


class BarberPortfolioSerializer(serializers.ModelSerializer):
    class Meta:
        model = BarberPortfolio
        fields = ['id', 'before_image', 'after_image', 'caption', 'service', 'likes', 'is_featured', 'status', 'rejection_reason', 'created_at']
        read_only_fields = ['barber', 'likes', 'status', 'rejection_reason']


class BarberRegisterSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=150)
    gender = serializers.ChoiceField(choices=['male', 'female'], default='male')
    region_id = serializers.IntegerField()
    district_id = serializers.IntegerField()
    salon_id = serializers.IntegerField(required=False, allow_null=True)
    specialization = serializers.CharField(max_length=200, required=False, allow_blank=True)
    bio = serializers.CharField(required=False, allow_blank=True)

    def create(self, validated_data):
        from apps.users.models import Region, District
        from apps.salons.models import Salon
        user = self.context['request'].user
        user.full_name = validated_data['full_name']
        user.role = 'barber'
        user.save()

        salon = None
        if validated_data.get('salon_id'):
            salon = Salon.objects.filter(pk=validated_data['salon_id']).first()

        barber, _ = Barber.objects.get_or_create(
            user=user,
            defaults={
                'salon': salon,
                'gender': validated_data.get('gender', 'male'),
                'specialization': validated_data.get('specialization', ''),
                'bio': validated_data.get('bio', ''),
            }
        )
        return barber


class CustomerNoteSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.full_name', read_only=True)
    customer_phone = serializers.CharField(source='customer.phone', read_only=True)

    class Meta:
        model = CustomerNote
        fields = ['id', 'customer', 'customer_name', 'customer_phone', 'note', 'is_vip', 'created_at', 'updated_at']
        read_only_fields = ['barber']


class VacationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vacation
        fields = ['id', 'start_date', 'end_date', 'reason', 'is_approved', 'created_at']
        read_only_fields = ['barber', 'is_approved']
