from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from .models import Region, District, CustomerProfile
from .serializers import (
    SendOTPSerializer, VerifyOTPSerializer,
    UserSerializer, UserUpdateSerializer,
    CustomerProfileSerializer, RegionSerializer, DistrictSerializer,
)

User = get_user_model()


class SendOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = SendOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({'message': 'OTP kod yuborildi', 'success': True})


class VerifyOTPView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user, created = serializer.get_or_create_user()
        tokens = serializer.get_tokens(user)
        return Response({
            'success': True,
            'is_new_user': created,
            'user': UserSerializer(user).data,
            'tokens': tokens,
        }, status=status.HTTP_200_OK)


class PhonePasswordLoginView(APIView):
    """POST /auth/login/ — phone + password login for barbers."""
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from django.contrib.auth import authenticate
        phone = request.data.get('phone', '').strip()
        password = request.data.get('password', '').strip()

        if not phone or not password:
            return Response({'error': 'Telefon va parol kiritilishi shart'}, status=400)

        user = authenticate(request, phone=phone, password=password)
        if user is None:
            return Response({'error': "Telefon raqam yoki parol noto'g'ri"}, status=401)

        refresh = RefreshToken.for_user(user)
        tokens = {'access': str(refresh.access_token), 'refresh': str(refresh)}

        barber_status = None
        try:
            barber_status = user.barber_profile.status
        except Exception:
            pass

        return Response({
            'tokens': tokens,
            'user': {
                **UserSerializer(user).data,
                'status': barber_status,
            },
        })


class LogoutView(APIView):
    def post(self, request):
        try:
            refresh_token = request.data.get('refresh')
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({'message': 'Muvaffaqiyatli chiqildi'})
        except Exception:
            return Response({'message': 'Chiqishda xatolik'}, status=status.HTTP_400_BAD_REQUEST)


class MeView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method in ['PUT', 'PATCH']:
            return UserUpdateSerializer
        return UserSerializer

    def destroy(self, request, *args, **kwargs):
        user = self.get_object()
        user.is_active = False
        user.save()
        return Response({'message': 'Hisob o\'chirildi'}, status=status.HTTP_204_NO_CONTENT)


class CustomerProfileView(generics.RetrieveAPIView):
    serializer_class = CustomerProfileSerializer

    def get_object(self):
        profile, _ = CustomerProfile.objects.get_or_create(user=self.request.user)
        return profile


class RegionListView(generics.ListAPIView):
    queryset = Region.objects.all()
    serializer_class = RegionSerializer
    permission_classes = [permissions.AllowAny]


class DistrictListView(generics.ListAPIView):
    serializer_class = DistrictSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = District.objects.all()
        region_id = self.request.query_params.get('region')
        if region_id:
            queryset = queryset.filter(region_id=region_id)
        return queryset


class AdminUserListView(generics.ListAPIView):
    queryset = User.objects.all().select_related('customer_profile')
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]
    filterset_fields = ['role', 'is_active', 'is_verified', 'gender']
    search_fields = ['phone', 'full_name', 'email']
    ordering_fields = ['date_joined', 'full_name']
