from rest_framework import serializers
from .models import Payment, SubscriptionPlan, Subscription


class PaymentSerializer(serializers.ModelSerializer):
    booking_date = serializers.DateField(source='booking.date', read_only=True)
    barber_name = serializers.CharField(source='booking.barber.user.full_name', read_only=True)

    class Meta:
        model = Payment
        fields = ['id', 'booking', 'booking_date', 'barber_name', 'amount', 'method', 'status', 'transaction_id', 'paid_at', 'created_at']


class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = '__all__'


class SubscriptionSerializer(serializers.ModelSerializer):
    plan = SubscriptionPlanSerializer(read_only=True)

    class Meta:
        model = Subscription
        fields = '__all__'
