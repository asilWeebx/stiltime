from django.urls import path
from .views import PaymentListView, PaymentDetailView, AdminPaymentListView

urlpatterns = [
    path('my/', PaymentListView.as_view(), name='payment-list'),
    path('<int:pk>/', PaymentDetailView.as_view(), name='payment-detail'),
    path('admin/list/', AdminPaymentListView.as_view(), name='admin-payment-list'),
]
