from rest_framework import serializers
from .models import Review
from apps.users.serializers import UserSerializer


class ReviewSerializer(serializers.ModelSerializer):
    customer_name = serializers.SerializerMethodField()
    customer_avatar = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = [
            'id', 'customer', 'customer_name', 'customer_avatar',
            'booking', 'salon', 'barber', 'rating', 'comment',
            'is_anonymous', 'likes', 'reply', 'replied_at', 'created_at',
        ]
        read_only_fields = ['customer', 'likes', 'reply', 'replied_at']

    def get_customer_name(self, obj):
        if obj.is_anonymous:
            return 'Anonim'
        return obj.customer.full_name or str(obj.customer.phone)

    def get_customer_avatar(self, obj):
        if obj.is_anonymous:
            return None
        req = self.context.get('request')
        if obj.customer.avatar and req:
            return req.build_absolute_uri(obj.customer.avatar.url)
        return None

    def validate(self, data):
        user = self.context['request'].user
        if data.get('booking') and Review.objects.filter(booking=data['booking']).exists():
            raise serializers.ValidationError({'booking': 'Bu bron uchun allaqachon sharh yozilgan'})
        return data

    def create(self, validated_data):
        review = Review.objects.create(
            customer=self.context['request'].user,
            **validated_data
        )
        self._update_rating(review)
        return review

    def _update_rating(self, review):
        from django.db.models import Avg
        if review.barber:
            barber = review.barber
            agg = Review.objects.filter(barber=barber, is_approved=True).aggregate(
                avg=Avg('rating'), count=__import__('django.db.models', fromlist=['Count']).Count('id')
            )
            barber.rating = agg['avg'] or 0
            barber.total_reviews = agg['count'] or 0
            barber.save()
        if review.salon:
            salon = review.salon
            from django.db.models import Avg, Count
            agg = Review.objects.filter(salon=salon, is_approved=True).aggregate(
                avg=Avg('rating'), count=Count('id')
            )
            salon.rating = agg['avg'] or 0
            salon.total_reviews = agg['count'] or 0
            salon.save()
