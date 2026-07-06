from django.urls import path
from .views import (
    AvailableSlotsView, BookingCreateView, BookingListView,
    BookingDetailView, BookingCancelView,
    BarberBookingListView, WalkInBookingCreateView, WalkInBookingUpdateView,
    BarberBookingUpdateView,
    BarberPendingBookingsView, BarberBookingRescheduleView,
    AdminBookingListView,
)

urlpatterns = [
    path('slots/', AvailableSlotsView.as_view(), name='available-slots'),
    path('create/', BookingCreateView.as_view(), name='booking-create'),
    path('', BookingCreateView.as_view(), name='booking-create-root'),  # POST /bookings/
    path('my/', BookingListView.as_view(), name='booking-list'),
    path('<int:pk>/', BookingDetailView.as_view(), name='booking-detail'),
    path('<int:pk>/cancel/', BookingCancelView.as_view(), name='booking-cancel'),

    path('barber/list/', BarberBookingListView.as_view(), name='barber-bookings'),
    path('barber/walk-in/', WalkInBookingCreateView.as_view(), name='walk-in-create'),
    path('walk-in/', WalkInBookingCreateView.as_view(), name='walk-in-create-alt'),
    path('barber/walk-in/<int:pk>/update/', WalkInBookingUpdateView.as_view(), name='walk-in-update'),
    path('barber/pending/', BarberPendingBookingsView.as_view(), name='barber-pending-bookings'),
    path('barber/<int:pk>/update/', BarberBookingUpdateView.as_view(), name='barber-booking-update'),
    path('barber/<int:pk>/reschedule/', BarberBookingRescheduleView.as_view(), name='barber-booking-reschedule'),

    path('admin/list/', AdminBookingListView.as_view(), name='admin-bookings'),
]
