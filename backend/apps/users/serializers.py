from rest_framework import serializers
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User, OTPCode, CustomerProfile, Region, District
import random
import string
from django.utils import timezone
from datetime import timedelta
from django.conf import settings


class RegionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Region
        fields = ['id', 'name', 'name_uz', 'name_ru', 'name_en']


class DistrictSerializer(serializers.ModelSerializer):
    region_name = serializers.CharField(source='region.name', read_only=True)

    class Meta:
        model = District
        fields = ['id', 'region', 'region_name', 'name', 'name_uz', 'name_ru', 'name_en']


class SendOTPSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)

    def validate_phone(self, value):
        value = value.strip().replace(' ', '')
        if not value.startswith('+'):
            if value.startswith('998'):
                value = '+' + value
            elif value.startswith('0'):
                value = '+998' + value[1:]
            else:
                value = '+998' + value
        return value

    def save(self):
        phone = self.validated_data['phone']
        OTPCode.objects.filter(phone=phone, is_used=False).update(is_used=True)
        code = ''.join([str(random.randint(0, 9)) for _ in range(settings.OTP_LENGTH)])
        expires_at = timezone.now() + timedelta(minutes=settings.OTP_EXPIRY_MINUTES)
        otp = OTPCode.objects.create(phone=phone, code=code, expires_at=expires_at)
        # In production: send via Eskiz SMS
        print(f"[OTP] {phone}: {code}")
        return otp


class VerifyOTPSerializer(serializers.Serializer):
    phone = serializers.CharField(max_length=20)
    code = serializers.CharField(max_length=10)

    def validate(self, data):
        phone = data['phone'].strip()
        if not phone.startswith('+'):
            phone = '+998' + phone
        data['phone'] = phone

        try:
            otp = OTPCode.objects.filter(
                phone=phone, is_used=False
            ).latest('created_at')
        except OTPCode.DoesNotExist:
            raise serializers.ValidationError({'code': 'OTP kod topilmadi'})

        otp.attempts += 1
        otp.save()

        if otp.attempts > settings.OTP_MAX_ATTEMPTS:
            raise serializers.ValidationError({'code': 'Urinishlar soni tugadi'})
        if otp.is_expired:
            raise serializers.ValidationError({'code': 'OTP kod muddati tugagan'})
        if otp.code != data['code']:
            raise serializers.ValidationError({'code': 'Noto\'g\'ri kod'})

        otp.is_used = True
        otp.save()
        data['otp'] = otp
        return data

    def get_or_create_user(self):
        phone = self.validated_data['phone']
        user, created = User.objects.get_or_create(phone=phone)
        if created:
            user.is_verified = True
            user.save()
            CustomerProfile.objects.create(
                user=user,
                referral_code=self._generate_referral_code()
            )
        return user, created

    def get_tokens(self, user):
        refresh = RefreshToken.for_user(user)
        return {
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        }

    def _generate_referral_code(self):
        while True:
            code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            if not CustomerProfile.objects.filter(referral_code=code).exists():
                return code


class UserSerializer(serializers.ModelSerializer):
    phone = serializers.SerializerMethodField()
    loyalty_points = serializers.SerializerMethodField()
    referral_code = serializers.SerializerMethodField()
    is_vip = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            'id', 'phone', 'full_name', 'email', 'avatar',
            'gender', 'date_of_birth', 'role', 'language',
            'is_verified', 'date_joined',
            'notification_booking', 'notification_promotions',
            'notification_reminders', 'reminder_minutes',
            'loyalty_points', 'referral_code', 'is_vip',
        ]
        read_only_fields = ['id', 'phone', 'role', 'is_verified', 'date_joined']

    def get_phone(self, obj):
        return str(obj.phone) if obj.phone else ''

    def get_loyalty_points(self, obj):
        try:
            return obj.customer_profile.loyalty_points
        except Exception:
            return 0

    def get_referral_code(self, obj):
        try:
            return obj.customer_profile.referral_code
        except Exception:
            return None

    def get_is_vip(self, obj):
        try:
            return obj.customer_profile.is_vip
        except Exception:
            return False


class UserUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'full_name', 'email', 'avatar', 'gender',
            'date_of_birth', 'language', 'fcm_token',
            'notification_booking', 'notification_promotions',
            'notification_reminders', 'reminder_minutes',
        ]


class CustomerProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)

    class Meta:
        model = CustomerProfile
        fields = '__all__'
