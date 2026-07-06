from rest_framework import generics, status, permissions, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend
from .models import (
    Category, Salon, Branch, Service, PromotionBanner, Coupon,
    FavoriteSalon, WorkingHours, SalonImage
)
from .serializers import (
    CategorySerializer, SalonListSerializer, SalonDetailSerializer,
    BranchSerializer, ServiceSerializer, PromotionBannerSerializer,
    CouponSerializer, CouponValidateSerializer, WorkingHoursSerializer,
    SalonImageSerializer,
)


class CategoryListView(generics.ListAPIView):
    queryset = Category.objects.filter(is_active=True)
    serializer_class = CategorySerializer
    permission_classes = [permissions.AllowAny]


class SalonListView(generics.ListAPIView):
    serializer_class = SalonListSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['type', 'region', 'district', 'is_verified', 'is_featured']
    search_fields = ['name', 'address']
    ordering_fields = ['rating', 'total_bookings', 'created_at']

    def get_queryset(self):
        from django.db.models import Q
        qs = Salon.objects.filter(is_active=True).prefetch_related('categories')
        category_id = self.request.query_params.get('category')
        if category_id:
            qs = qs.filter(
                Q(categories__id=category_id) |
                Q(services__category__id=category_id) |
                Q(barbers__services__category__id=category_id)
            ).distinct()
        gender = self.request.query_params.get('gender')
        if gender:
            qs = qs.filter(Q(gender=gender) | Q(gender='unisex'))
        return qs


class SalonDetailView(generics.RetrieveAPIView):
    queryset = Salon.objects.filter(is_active=True)
    serializer_class = SalonDetailSerializer
    permission_classes = [permissions.AllowAny]


class SalonReviewsView(generics.ListAPIView):
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        from apps.reviews.models import Review
        return Review.objects.filter(salon_id=self.kwargs['pk'], is_approved=True).select_related('customer')

    def get_serializer_class(self):
        from apps.reviews.serializers import ReviewSerializer
        return ReviewSerializer


class SalonServicesView(generics.ListAPIView):
    serializer_class = ServiceSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Service.objects.filter(salon_id=self.kwargs['pk'], is_active=True)


class FavoriteSalonToggleView(APIView):
    def post(self, request, pk):
        try:
            salon = Salon.objects.get(pk=pk, is_active=True)
        except Salon.DoesNotExist:
            return Response({'error': 'Salon topilmadi'}, status=404)

        fav, created = FavoriteSalon.objects.get_or_create(user=request.user, salon=salon)
        if not created:
            fav.delete()
            return Response({'is_favorite': False, 'message': 'Sevimlilardan olib tashlandi'})
        return Response({'is_favorite': True, 'message': "Sevimlilarga qo'shildi"})


class FavoriteSalonListView(generics.ListAPIView):
    serializer_class = SalonListSerializer

    def get_queryset(self):
        salon_ids = FavoriteSalon.objects.filter(user=self.request.user).values_list('salon_id', flat=True)
        return Salon.objects.filter(pk__in=salon_ids, is_active=True)


class SalonBarbersView(generics.ListAPIView):
    """GET /salons/{pk}/barbers/ — list approved barbers in a salon."""
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        from apps.barbers.models import Barber
        return Barber.objects.filter(
            salon_id=self.kwargs['pk'],
            status=Barber.STATUS_APPROVED,
        ).select_related('user')

    def get_serializer_class(self):
        from apps.barbers.serializers import BarberListSerializer
        return BarberListSerializer


class BannerListView(generics.ListAPIView):
    serializer_class = PromotionBannerSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        from django.utils import timezone
        from django.db.models import Q
        now = timezone.now()
        return PromotionBanner.objects.filter(
            is_active=True
        ).filter(
            Q(starts_at__isnull=True) | Q(starts_at__lte=now)
        ).filter(
            Q(ends_at__isnull=True) | Q(ends_at__gte=now)
        ).order_by('order')


class CouponValidateView(APIView):
    def post(self, request):
        serializer = CouponValidateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            from django.utils import timezone
            coupon = Coupon.objects.get(
                code=data['code'],
                is_active=True,
                salon_id=data['salon_id'],
            )
            now = timezone.now()
            if coupon.starts_at and coupon.starts_at > now:
                return Response({'valid': False, 'message': 'Kupon hali kuchga kirmagan'})
            if coupon.expires_at and coupon.expires_at < now:
                return Response({'valid': False, 'message': 'Kupon muddati tugagan'})
            if coupon.max_uses and coupon.used_count >= coupon.max_uses:
                return Response({'valid': False, 'message': 'Kupon foydalanish chegarasi tugagan'})
            if data['amount'] < coupon.min_amount:
                return Response({'valid': False, 'message': f"Minimal summa: {coupon.min_amount} so'm"})

            discount = 0
            if coupon.discount_type == Coupon.TYPE_PERCENT:
                discount = data['amount'] * coupon.discount_value / 100
            else:
                discount = min(coupon.discount_value, data['amount'])

            return Response({
                'valid': True,
                'coupon': CouponSerializer(coupon).data,
                'discount': discount,
                'final_amount': data['amount'] - discount,
            })
        except Coupon.DoesNotExist:
            return Response({'valid': False, 'message': 'Kupon topilmadi'})


# ---- Admin views ----

class AdminSalonListView(generics.ListCreateAPIView):
    queryset = Salon.objects.all().select_related('region', 'district', 'owner')
    serializer_class = SalonDetailSerializer
    permission_classes = [permissions.IsAdminUser]
    filterset_fields = ['is_active', 'is_verified', 'type', 'region', 'district']
    search_fields = ['name', 'phone', 'email']


class AdminSalonDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Salon.objects.all()
    serializer_class = SalonDetailSerializer
    permission_classes = [permissions.IsAdminUser]


class AdminCategoryView(generics.ListCreateAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAdminUser]


class AdminCategoryDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [permissions.IsAdminUser]


class AdminServiceView(generics.ListCreateAPIView):
    queryset = Service.objects.all().select_related('salon', 'category')
    serializer_class = ServiceSerializer
    permission_classes = [permissions.IsAdminUser]
    filterset_fields = ['salon', 'category', 'is_active']


class AdminBannerView(generics.ListCreateAPIView):
    queryset = PromotionBanner.objects.all()
    serializer_class = PromotionBannerSerializer
    permission_classes = [permissions.IsAdminUser]


class AdminWorkingHoursView(APIView):
    """GET /salons/admin/salons/<pk>/working-hours/ — list hours
       PUT /salons/admin/salons/<pk>/working-hours/ — bulk set all 7 days"""
    permission_classes = [permissions.IsAdminUser]

    def get(self, request, pk):
        salon = Salon.objects.get(pk=pk)
        hours = WorkingHours.objects.filter(salon=salon).order_by('day_of_week')
        data = WorkingHoursSerializer(hours, many=True).data
        return Response(data)

    def put(self, request, pk):
        salon = Salon.objects.get(pk=pk)
        days = request.data  # list of {day_of_week, open_time, close_time, is_day_off}
        for d in days:
            WorkingHours.objects.update_or_create(
                salon=salon,
                day_of_week=d['day_of_week'],
                defaults={
                    'open_time': d.get('open_time', '09:00'),
                    'close_time': d.get('close_time', '20:00'),
                    'is_day_off': d.get('is_day_off', False),
                },
            )
        hours = WorkingHours.objects.filter(salon=salon).order_by('day_of_week')
        return Response(WorkingHoursSerializer(hours, many=True).data)


class AdminBannerDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = PromotionBanner.objects.all()
    serializer_class = PromotionBannerSerializer
    permission_classes = [permissions.IsAdminUser]


class AdminSalonImagesView(APIView):
    """
    GET  /salons/admin/salons/<pk>/images/         — list gallery images
    POST /salons/admin/salons/<pk>/images/         — upload one image
    DELETE /salons/admin/salons/<pk>/images/<img>/ — delete one image
    """
    permission_classes = [permissions.IsAdminUser]

    def get(self, request, pk):
        images = SalonImage.objects.filter(salon_id=pk).order_by('order', '-created_at')
        return Response(SalonImageSerializer(images, many=True, context={'request': request}).data)

    def post(self, request, pk):
        salon = Salon.objects.get(pk=pk)
        image_file = request.FILES.get('image')
        if not image_file:
            return Response({'error': 'image field required'}, status=status.HTTP_400_BAD_REQUEST)
        img = SalonImage.objects.create(
            salon=salon,
            image=image_file,
            caption=request.data.get('caption', ''),
            order=request.data.get('order', 0),
        )
        return Response(SalonImageSerializer(img, context={'request': request}).data, status=status.HTTP_201_CREATED)


class AdminSalonImageDetailView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def delete(self, request, pk, img_id):
        try:
            img = SalonImage.objects.get(pk=img_id, salon_id=pk)
        except SalonImage.DoesNotExist:
            return Response({'error': 'Not found'}, status=status.HTTP_404_NOT_FOUND)
        img.image.delete(save=False)
        img.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
