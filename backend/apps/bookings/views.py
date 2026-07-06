from rest_framework import generics, status, permissions
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
from datetime import datetime, timedelta, time
from .models import Booking, WalkInBooking, TimeSlot
from .serializers import (
    BookingSerializer, BookingCreateSerializer,
    WalkInBookingSerializer, AvailableSlotsSerializer
)
from apps.barbers.models import Barber
from apps.salons.models import WorkingHours


class AvailableSlotsView(APIView):
    def post(self, request):
        serializer = AvailableSlotsSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        try:
            barber = Barber.objects.get(pk=data['barber_id'], status=Barber.STATUS_APPROVED)
        except Barber.DoesNotExist:
            return Response({'error': 'Sartarosh topilmadi'}, status=404)

        target_date = data['date']
        day_of_week = target_date.weekday()

        try:
            working = barber.working_hours.get(day_of_week=day_of_week, is_day_off=False)
        except WorkingHours.DoesNotExist:
            return Response({'slots': [], 'message': 'Dam olish kuni'})

        from apps.salons.models import Service
        service_ids = data.get('service_ids', [])
        total_duration = 30
        if service_ids:
            services = Service.objects.filter(pk__in=service_ids)
            total_duration = sum(s.duration for s in services)

        existing_bookings = Booking.objects.filter(
            barber=barber, date=target_date,
            status__in=[Booking.STATUS_PENDING, Booking.STATUS_CONFIRMED, Booking.STATUS_IN_PROGRESS]
        ).values('start_time', 'end_time')

        blocked_intervals = [(b['start_time'], b['end_time']) for b in existing_bookings]

        walk_ins = WalkInBooking.objects.filter(barber=barber, date=target_date).values('start_time', 'end_time')
        blocked_intervals += [(w['start_time'], w['end_time']) for w in walk_ins]

        slots = []
        current = datetime.combine(target_date, working.open_time)
        end_of_day = datetime.combine(target_date, working.close_time)
        slot_end_dt = current + timedelta(minutes=total_duration)

        while slot_end_dt <= end_of_day:
            slot_start_t = current.time()
            slot_end_t = slot_end_dt.time()
            is_available = True

            for blk_start, blk_end in blocked_intervals:
                if slot_start_t < blk_end and slot_end_t > blk_start:
                    is_available = False
                    break

            if datetime.combine(target_date, slot_start_t) > datetime.now():
                slots.append({
                    'start_time': slot_start_t.strftime('%H:%M'),
                    'end_time': slot_end_t.strftime('%H:%M'),
                    'is_available': is_available,
                })

            current += timedelta(minutes=working.slot_duration or 30)
            slot_end_dt = current + timedelta(minutes=total_duration)

        return Response({'slots': slots, 'total_duration': total_duration})


class BookingCreateView(generics.CreateAPIView):
    serializer_class = BookingCreateSerializer

    def create(self, request, *args, **kwargs):
        from apps.notifications.tasks import notify_user
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        booking = serializer.create(serializer.validated_data)
        # Notify barber about new booking
        barber_user = booking.barber.user
        notify_user(
            barber_user,
            title='Yangi bron! 🗓',
            body=f'{booking.customer.full_name if booking.customer else "Mijoz"} '
                 f'{booking.date} kuni soat {booking.start_time.strftime("%H:%M")} '
                 f'da bron qildi',
            notification_type='booking',
            data={'booking_id': booking.pk, 'action': 'new_booking'},
        )
        return Response(BookingSerializer(booking, context={'request': request}).data, status=201)


class BookingListView(generics.ListAPIView):
    serializer_class = BookingSerializer

    def get_queryset(self):
        user = self.request.user
        qs = Booking.objects.filter(customer=user).select_related(
            'barber__user', 'salon'
        ).prefetch_related('services').order_by('-date', '-start_time')
        status_filter = self.request.query_params.get('status')
        status_in = self.request.query_params.get('status__in')
        if status_in:
            qs = qs.filter(status__in=status_in.split(','))
        elif status_filter:
            qs = qs.filter(status=status_filter)
        return qs


class BookingDetailView(generics.RetrieveAPIView):
    serializer_class = BookingSerializer

    def get_queryset(self):
        return Booking.objects.filter(customer=self.request.user)


class BookingCancelView(APIView):
    def post(self, request, pk):
        try:
            booking = Booking.objects.get(pk=pk, customer=request.user)
        except Booking.DoesNotExist:
            return Response({'error': 'Bron topilmadi'}, status=404)

        if booking.status not in [Booking.STATUS_PENDING, Booking.STATUS_CONFIRMED]:
            return Response({'error': 'Bu bronni bekor qilib bo\'lmaydi'}, status=400)

        booking_dt = datetime.combine(booking.date, booking.start_time)
        if timezone.make_aware(booking_dt) - timezone.now() < timedelta(hours=1):
            return Response({'error': '1 soatdan kam vaqt qolgan bronni bekor qilib bo\'lmaydi'}, status=400)

        booking.status = Booking.STATUS_CANCELLED
        booking.cancellation_reason = request.data.get('reason', '')
        booking.save()
        return Response({'message': 'Bron bekor qilindi'})


# ---- Barber views ----

class BarberBookingListView(generics.ListAPIView):
    serializer_class = BookingSerializer

    def get_queryset(self):
        barber = self.request.user.barber_profile
        qs = Booking.objects.filter(barber=barber).select_related('customer', 'salon').prefetch_related('services')
        date_str = self.request.query_params.get('date')
        if date_str:
            qs = qs.filter(date=date_str)
        status_filter = self.request.query_params.get('status')
        if status_filter:
            qs = qs.filter(status=status_filter)
        return qs

    def list(self, request, *args, **kwargs):
        barber = request.user.barber_profile
        booking_data = list(BookingSerializer(self.get_queryset(), many=True, context={'request': request}).data)

        # Merge walk-in bookings into the same response
        date_str = request.query_params.get('date')
        walk_in_qs = WalkInBooking.objects.filter(barber=barber).prefetch_related('services')
        if date_str:
            walk_in_qs = walk_in_qs.filter(date=date_str)

        salon_name = barber.salon.name if barber.salon else ''
        for w in walk_in_qs:
            services_data = [
                {'id': s.id, 'name': s.name, 'price': float(s.price), 'duration': s.duration}
                for s in w.services.all()
            ]
            total_duration = sum(s['duration'] for s in services_data) if services_data else 30
            booking_data.append({
                'id': w.id,
                'walk_in_id': w.id,
                'is_walk_in': True,
                'customer_name': w.customer_name or 'Bevosita mijoz',
                'customer_phone': w.customer_phone,
                'date': str(w.date),
                'start_time': str(w.start_time),
                'end_time': str(w.end_time),
                'status': w.status,
                'source': 'walk_in',
                'salon_name': salon_name,
                'services': services_data,
                'final_price': float(w.total_price),
                'total_price': float(w.total_price),
                'total_duration': total_duration,
                'notes': w.notes,
                'created_at': w.created_at.isoformat() if w.created_at else None,
            })

        return Response(booking_data)


class WalkInBookingCreateView(generics.CreateAPIView):
    serializer_class = WalkInBookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        barber = self.request.user.barber_profile
        serializer.save(barber=barber)


class WalkInBookingUpdateView(APIView):
    def patch(self, request, pk):
        try:
            walk_in = WalkInBooking.objects.get(pk=pk, barber=request.user.barber_profile)
        except WalkInBooking.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)
        new_status = request.data.get('status')
        allowed = [WalkInBooking.STATUS_IN_PROGRESS, WalkInBooking.STATUS_COMPLETED, WalkInBooking.STATUS_CANCELLED]
        if new_status not in allowed:
            return Response({'error': "Noto'g'ri status"}, status=400)
        walk_in.status = new_status
        walk_in.save(update_fields=['status'])
        return Response({'id': walk_in.id, 'status': walk_in.status, 'is_walk_in': True})


class BarberBookingUpdateView(APIView):
    def patch(self, request, pk):
        try:
            booking = Booking.objects.get(pk=pk, barber=request.user.barber_profile)
        except Booking.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)

        new_status = request.data.get('status')
        allowed = [
            Booking.STATUS_CONFIRMED, Booking.STATUS_IN_PROGRESS,
            Booking.STATUS_COMPLETED, Booking.STATUS_NO_SHOW,
            Booking.STATUS_CANCELLED,
        ]
        if new_status not in allowed:
            return Response({'error': 'Noto\'g\'ri status'}, status=400)

        booking.status = new_status
        if new_status == Booking.STATUS_CANCELLED:
            booking.cancellation_reason = request.data.get('reason', 'Sartarosh tomonidan bekor qilindi')
        booking.save()

        # Notify customer about status change
        if booking.customer:
            from apps.notifications.tasks import notify_user
            _STATUS_MSG = {
                Booking.STATUS_CONFIRMED: ('Bron tasdiqlandi ✅', f'{booking.barber.user.full_name} sizning broningizni tasdiqladi'),
                Booking.STATUS_CANCELLED: ('Bron bekor qilindi ❌', f'{booking.barber.user.full_name} sizning broningizni bekor qildi'),
                Booking.STATUS_IN_PROGRESS: ('Xizmat boshlandi 💈', f'Siz hozir {booking.salon.name}dasiz'),
                Booking.STATUS_COMPLETED: ('Xizmat yakunlandi ⭐', 'Xizmatdan minnatdormiz! Izoh qoldiring'),
            }
            if new_status in _STATUS_MSG:
                title, body = _STATUS_MSG[new_status]
                notify_user(
                    booking.customer, title=title, body=body,
                    notification_type='booking',
                    data={'booking_id': booking.pk, 'action': new_status},
                )

        return Response(BookingSerializer(booking, context={'request': request}).data)


class BarberPendingBookingsView(APIView):
    """
    GET /bookings/barber/pending/
    1. Auto-cancel bookings older than 10 minutes
    2. Return remaining pending bookings with full details
    """

    def get(self, request):
        barber = request.user.barber_profile
        cutoff = timezone.now() - timedelta(minutes=10)

        # Auto-cancel stale pending bookings
        stale = Booking.objects.filter(
            barber=barber,
            status=Booking.STATUS_PENDING,
            created_at__lt=cutoff,
        )
        stale.update(
            status=Booking.STATUS_CANCELLED,
            cancellation_reason='10 daqiqa ichida tasdiqlanmadi — avtomatik bekor qilindi',
        )

        # Return remaining pending
        pending = Booking.objects.filter(
            barber=barber,
            status=Booking.STATUS_PENDING,
        ).select_related('customer', 'salon', 'barber').prefetch_related('services').order_by('created_at')

        data = []
        for b in pending:
            services_list = [
                {'id': s.id, 'name': s.name, 'price': str(s.price), 'duration': s.duration}
                for s in b.services.all()
            ]
            # Seconds remaining out of 600 (10 min)
            elapsed = (timezone.now() - b.created_at).total_seconds()
            seconds_remaining = max(0, 600 - int(elapsed))

            data.append({
                'id': b.pk,
                'customer_name': b.customer.full_name if b.customer else 'Noma\'lum',
                'customer_phone': str(b.customer.phone) if b.customer and b.customer.phone else None,
                'salon_name': b.salon.name if b.salon else '',
                'date': str(b.date),
                'start_time': b.start_time.strftime('%H:%M'),
                'end_time': b.end_time.strftime('%H:%M'),
                'total_duration': b.total_duration,
                'final_price': str(b.final_price),
                'services': services_list,
                'notes': b.notes,
                'created_at': b.created_at.isoformat(),
                'seconds_remaining': seconds_remaining,
            })

        return Response(data)


class BarberBookingRescheduleView(APIView):
    """
    PATCH /bookings/barber/<pk>/reschedule/
    Takes: date, start_time, notes (optional)
    Recalculates end_time from total_duration
    """

    def patch(self, request, pk):
        try:
            booking = Booking.objects.get(pk=pk, barber=request.user.barber_profile)
        except Booking.DoesNotExist:
            return Response({'error': 'Bron topilmadi'}, status=404)

        if booking.status not in [Booking.STATUS_PENDING, Booking.STATUS_CONFIRMED]:
            return Response({'error': 'Bu bronni ko\'chirib bo\'lmaydi'}, status=400)

        date_str = request.data.get('date')
        start_time_str = request.data.get('start_time')
        notes = request.data.get('notes')

        if not date_str or not start_time_str:
            return Response({'error': 'date va start_time kerak'}, status=400)

        try:
            new_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response({'error': 'Noto\'g\'ri sana formati (YYYY-MM-DD)'}, status=400)

        try:
            new_start = datetime.strptime(start_time_str, '%H:%M').time()
        except ValueError:
            try:
                new_start = datetime.strptime(start_time_str, '%H:%M:%S').time()
            except ValueError:
                return Response({'error': 'Noto\'g\'ri vaqt formati (HH:MM)'}, status=400)

        # Check for conflicts (excluding this booking)
        start_dt = datetime.combine(new_date, new_start)
        end_dt = start_dt + timedelta(minutes=booking.total_duration)
        new_end = end_dt.time()

        conflicting = Booking.objects.filter(
            barber=booking.barber,
            date=new_date,
            status__in=[Booking.STATUS_PENDING, Booking.STATUS_CONFIRMED, Booking.STATUS_IN_PROGRESS],
        ).exclude(pk=pk).filter(
            start_time__lt=new_end,
            end_time__gt=new_start,
        )
        if conflicting.exists():
            return Response({'error': 'Bu vaqt band'}, status=400)

        booking.date = new_date
        booking.start_time = new_start
        booking.end_time = new_end
        if notes is not None:
            booking.notes = notes
        booking.save()

        return Response(BookingSerializer(booking, context={'request': request}).data)


# ---- Admin views ----

class AdminBookingListView(generics.ListAPIView):
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAdminUser]
    filterset_fields = ['status', 'source', 'date']
    search_fields = ['customer__phone', 'customer__full_name', 'barber__user__full_name']
    ordering_fields = ['date', 'created_at', 'final_price']

    def get_queryset(self):
        return Booking.objects.all().select_related('customer', 'barber__user', 'salon').prefetch_related('services')
