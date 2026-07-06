from rest_framework import generics, permissions
from .models import Payment
from .serializers import PaymentSerializer


class PaymentListView(generics.ListAPIView):
    serializer_class = PaymentSerializer

    def get_queryset(self):
        return Payment.objects.filter(customer=self.request.user).select_related('booking')


class PaymentDetailView(generics.RetrieveAPIView):
    serializer_class = PaymentSerializer

    def get_queryset(self):
        return Payment.objects.filter(customer=self.request.user)


class AdminPaymentListView(generics.ListAPIView):
    queryset = Payment.objects.all().select_related('customer', 'booking')
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAdminUser]
    filterset_fields = ['status', 'method']
    ordering_fields = ['created_at', 'amount']
