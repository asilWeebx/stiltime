from rest_framework import serializers
from django.utils import timezone
from datetime import datetime, timedelta
from .models import Booking, WalkInBooking, TimeSlot
from apps.salons.models import Service
from apps.barbers.models import Barber


class TimeSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = TimeSlot
        fields = ['id', 'date', 'start_time', 'end_time', 'is_available', 'is_blocked']


class BookingCreateSerializer(serializers.Serializer):
    barber_id = serializers.IntegerField()
    service_ids = serializers.ListField(child=serializers.IntegerField(), min_length=1)
    date = serializers.DateField()
    start_time = serializers.TimeField()
    coupon_code = serializers.CharField(required=False, allow_blank=True)
    notes = serializers.CharField(required=False, allow_blank=True)

    def validate_date(self, value):
        if value < timezone.now().date():
            raise serializers.ValidationError("O'tgan sana tanlanmadi")
        return value

    def validate(self, data):
        try:
            barber = Barber.objects.get(pk=data['barber_id'], status=Barber.STATUS_APPROVED)
        except Barber.DoesNotExist:
            raise serializers.ValidationError({'barber_id': 'Sartarosh topilmadi'})

        services = Service.objects.filter(pk__in=data['service_ids'])
        if services.count() != len(data['service_ids']):
            raise serializers.ValidationError({'service_ids': 'Ba\'zi xizmatlar topilmadi'})

        total_duration = sum(s.duration for s in services)
        total_price = sum(s.price for s in services)

        start_dt = datetime.combine(data['date'], data['start_time'])
        end_dt = start_dt + timedelta(minutes=total_duration)

        conflicting = Booking.objects.filter(
            barber=barber,
            date=data['date'],
            status__in=[Booking.STATUS_PENDING, Booking.STATUS_CONFIRMED, Booking.STATUS_IN_PROGRESS],
        ).filter(
            start_time__lt=end_dt.time(),
            end_time__gt=data['start_time'],
        )
        if conflicting.exists():
            raise serializers.ValidationError({'start_time': 'Bu vaqt band'})

        data['barber'] = barber
        data['services'] = services
        data['total_duration'] = total_duration
        data['total_price'] = total_price
        data['end_time'] = end_dt.time()
        return data

    def create(self, validated_data):
        customer = self.context['request'].user
        services = validated_data.pop('services')
        validated_data.pop('barber_id', None)
        validated_data.pop('service_ids', None)

        coupon_code = validated_data.pop('coupon_code', None)
        discount = 0
        coupon = None

        if coupon_code:
            from apps.salons.models import Coupon
            from django.utils import timezone as tz
            try:
                coupon = Coupon.objects.get(
                    code=coupon_code, is_active=True,
                    salon=validated_data['barber'].salon
                )
                now = tz.now()
                if coupon.starts_at and coupon.starts_at > now:
                    coupon = None
                elif coupon.expires_at and coupon.expires_at < now:
                    coupon = None
                else:
                    if coupon.discount_type == Coupon.TYPE_PERCENT:
                        discount = validated_data['total_price'] * coupon.discount_value / 100
                    else:
                        discount = min(coupon.discount_value, validated_data['total_price'])
                    coupon.used_count += 1
                    coupon.save()
            except Exception:
                coupon = None

        final_price = validated_data['total_price'] - discount
        booking = Booking.objects.create(
            customer=customer,
            salon=validated_data['barber'].salon,
            barber=validated_data['barber'],
            date=validated_data['date'],
            start_time=validated_data['start_time'],
            end_time=validated_data['end_time'],
            total_duration=validated_data['total_duration'],
            total_price=validated_data['total_price'],
            discount_amount=discount,
            final_price=final_price,
            coupon=coupon,
            notes=validated_data.get('notes', ''),
        )
        booking.services.set(services)
        return booking


class BookingSerializer(serializers.ModelSerializer):
    services = serializers.SerializerMethodField()
    barber_name = serializers.CharField(source='barber.user.full_name', read_only=True)
    salon_name = serializers.CharField(source='salon.name', read_only=True)
    salon_cover = serializers.SerializerMethodField()
    salon_address = serializers.CharField(source='salon.address', read_only=True)
    salon_latitude = serializers.DecimalField(source='salon.latitude', max_digits=10, decimal_places=8, read_only=True)
    salon_longitude = serializers.DecimalField(source='salon.longitude', max_digits=11, decimal_places=8, read_only=True)
    barber_avatar = serializers.SerializerMethodField()
    barber_cover = serializers.SerializerMethodField()
    barber_specialization = serializers.CharField(source='barber.specialization', read_only=True)
    barber_rating = serializers.DecimalField(source='barber.rating', max_digits=3, decimal_places=2, read_only=True)
    customer_name = serializers.SerializerMethodField()
    customer_phone = serializers.SerializerMethodField()
    has_review = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            'id', 'barber', 'barber_name', 'barber_avatar', 'barber_cover',
            'barber_specialization', 'barber_rating',
            'salon', 'salon_name', 'salon_cover', 'salon_address',
            'salon_latitude', 'salon_longitude', 'services',
            'date', 'start_time', 'end_time', 'total_duration',
            'total_price', 'discount_amount', 'final_price',
            'status', 'source', 'notes', 'cancellation_reason',
            'customer_name', 'customer_phone',
            'has_review',
            'created_at', 'updated_at',
        ]

    def get_has_review(self, obj):
        return hasattr(obj, 'review')

    def get_services(self, obj):
        return [{'id': s.id, 'name': s.name, 'price': str(s.price), 'duration': s.duration}
                for s in obj.services.all()]

    def get_barber_avatar(self, obj):
        req = self.context.get('request')
        if obj.barber.user.avatar and req:
            return req.build_absolute_uri(obj.barber.user.avatar.url)
        return None

    def get_barber_cover(self, obj):
        req = self.context.get('request')
        if obj.barber.cover_photo and req:
            return req.build_absolute_uri(obj.barber.cover_photo.url)
        return None

    def get_salon_cover(self, obj):
        req = self.context.get('request')
        if obj.salon and obj.salon.cover_image and req:
            return req.build_absolute_uri(obj.salon.cover_image.url)
        return None

    def get_customer_name(self, obj):
        if obj.customer:
            return obj.customer.full_name
        return None

    def get_customer_phone(self, obj):
        if obj.customer and obj.customer.phone:
            return str(obj.customer.phone)
        return None


class WalkInBookingSerializer(serializers.ModelSerializer):
    service_ids = serializers.ListField(
        child=serializers.IntegerField(), write_only=True, required=False, default=list
    )

    class Meta:
        model = WalkInBooking
        fields = [
            'id', 'barber', 'customer_name', 'customer_phone',
            'services', 'service_ids', 'date', 'start_time', 'end_time',
            'total_price', 'notes', 'created_at',
        ]
        read_only_fields = ['barber', 'end_time', 'total_price', 'services']

    def validate(self, data):
        service_ids = data.pop('service_ids', [])
        services = Service.objects.filter(pk__in=service_ids) if service_ids else Service.objects.none()

        total_duration = sum(s.duration for s in services) if services.exists() else 30
        total_price = sum(s.price for s in services) if services.exists() else 0

        start_time = data.get('start_time')
        date = data.get('date')
        if start_time and date:
            from datetime import datetime, timedelta
            start_dt = datetime.combine(date, start_time)
            end_dt = start_dt + timedelta(minutes=total_duration)
            data['end_time'] = end_dt.time()

        data['total_price'] = total_price
        data['_services'] = list(services)
        return data

    def create(self, validated_data):
        services = validated_data.pop('_services', [])
        validated_data['barber'] = self.context['request'].user.barber_profile
        instance = super().create(validated_data)
        if services:
            instance.services.set(services)
        return instance


class AvailableSlotsSerializer(serializers.Serializer):
    barber_id = serializers.IntegerField()
    date = serializers.DateField()
    service_ids = serializers.ListField(child=serializers.IntegerField(), required=False)
