from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Review
from .serializers import ReviewSerializer


class ReviewListCreateView(generics.ListCreateAPIView):
    serializer_class = ReviewSerializer

    def get_permissions(self):
        if self.request.method == 'GET':
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        qs = Review.objects.filter(is_approved=True).select_related('customer', 'barber', 'salon')
        barber_id = self.request.query_params.get('barber')
        salon_id = self.request.query_params.get('salon')
        if barber_id:
            qs = qs.filter(barber_id=barber_id)
        if salon_id:
            qs = qs.filter(salon_id=salon_id)
        return qs


class ReviewDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = ReviewSerializer

    def get_queryset(self):
        return Review.objects.filter(customer=self.request.user)


class ReviewReplyView(APIView):
    def post(self, request, pk):
        try:
            review = Review.objects.get(pk=pk, barber=request.user.barber_profile)
        except (Review.DoesNotExist, AttributeError):
            return Response({'error': 'Topilmadi'}, status=404)

        from django.utils import timezone
        review.reply = request.data.get('reply', '')
        review.replied_at = timezone.now()
        review.save()
        return Response({'message': 'Javob saqlandi'})
