from datetime import datetime, timedelta, date as date_type
from rest_framework import generics, status, permissions, filters
from rest_framework.response import Response
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend
from .models import Barber, BarberPortfolio, Vacation, FavoriteBarber, CustomerNote
from .serializers import (
    BarberListSerializer, BarberDetailSerializer, BarberPortfolioSerializer,
    BarberRegisterSerializer, BarberUpdateSerializer, CustomerNoteSerializer, VacationSerializer,
)


class BarberListView(generics.ListAPIView):
    serializer_class = BarberListSerializer
    permission_classes = [permissions.AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['salon', 'status', 'is_online', 'is_available']
    search_fields = ['user__full_name', 'specialization', 'bio']
    ordering_fields = ['rating', 'total_bookings', 'experience_years']

    def get_queryset(self):
        qs = Barber.objects.filter(
            status=Barber.STATUS_APPROVED, is_available=True
        ).select_related('user', 'salon')

        gender = self.request.query_params.get('gender')
        if gender:
            from django.db.models import Q
            # Filter barbers who serve this gender OR serve all (unisex/both)
            qs = qs.filter(Q(gender=gender) | Q(gender=''))

        salon_id = self.request.query_params.get('salon')
        if salon_id:
            qs = qs.filter(salon_id=salon_id)

        return qs


class BarberDetailView(generics.RetrieveAPIView):
    queryset = Barber.objects.filter(status=Barber.STATUS_APPROVED)
    serializer_class = BarberDetailSerializer
    permission_classes = [permissions.AllowAny]


class BarberPortfolioView(generics.ListAPIView):
    serializer_class = BarberPortfolioSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return BarberPortfolio.objects.filter(barber_id=self.kwargs['pk'], status='approved')


class PortfolioFeedView(generics.ListAPIView):
    """Public feed of featured portfolio items from all approved barbers."""
    serializer_class = BarberPortfolioSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = BarberPortfolio.objects.filter(
            barber__status='approved'
        ).select_related('barber__user').order_by('-is_featured', '-created_at')
        limit = int(self.request.query_params.get('limit', 20))
        return qs[:limit]


class BarberReviewsView(generics.ListAPIView):
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        from apps.reviews.models import Review
        return Review.objects.filter(barber_id=self.kwargs['pk'], is_approved=True).select_related('customer')

    def get_serializer_class(self):
        from apps.reviews.serializers import ReviewSerializer
        return ReviewSerializer


class BarberServicesView(generics.ListAPIView):
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        from apps.salons.models import Service
        barber = Barber.objects.get(pk=self.kwargs['pk'])
        return Service.objects.filter(salon=barber.salon, is_active=True)

    def get_serializer_class(self):
        from apps.salons.serializers import ServiceSerializer
        return ServiceSerializer


class FavoriteBarberToggleView(APIView):
    def post(self, request, pk):
        try:
            barber = Barber.objects.get(pk=pk, status=Barber.STATUS_APPROVED)
        except Barber.DoesNotExist:
            return Response({'error': 'Sartarosh topilmadi'}, status=404)
        fav, created = FavoriteBarber.objects.get_or_create(user=request.user, barber=barber)
        if not created:
            fav.delete()
            return Response({'is_favorite': False})
        return Response({'is_favorite': True})


class FavoriteBarberListView(generics.ListAPIView):
    serializer_class = BarberListSerializer

    def get_queryset(self):
        ids = FavoriteBarber.objects.filter(user=self.request.user).values_list('barber_id', flat=True)
        return Barber.objects.filter(pk__in=ids, status=Barber.STATUS_APPROVED)


class TopBarbersView(generics.ListAPIView):
    serializer_class = BarberListSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Barber.objects.filter(
            status=Barber.STATUS_APPROVED
        ).order_by('-rating', '-total_bookings')[:10]


class BarberRegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        from django.contrib.auth import get_user_model
        from apps.salons.models import Salon

        User = get_user_model()
        data = request.data

        first_name = str(data.get('first_name', '')).strip()
        last_name = str(data.get('last_name', '')).strip()
        full_name = str(data.get('full_name', '')).strip() or f"{first_name} {last_name}".strip()
        phone = str(data.get('phone', '')).strip()
        password = str(data.get('password', '')).strip()
        salon_id = data.get('salon')
        gender = str(data.get('gender', 'male')).strip()
        specialization = str(data.get('specialization', '')).strip()
        bio = str(data.get('bio', '')).strip()

        if not phone:
            return Response({'error': 'Telefon raqam kiritilmagan'}, status=400)
        if not full_name:
            return Response({'error': 'Ism familiya kiritilmagan'}, status=400)
        if not password or len(password) < 6:
            return Response({'error': "Parol kamida 6 ta belgidan iborat bo'lishi kerak"}, status=400)

        if User.objects.filter(phone=phone).exists():
            return Response({'error': "Bu telefon raqam allaqachon ro'yxatdan o'tgan"}, status=400)

        user = User.objects.create_user(
            phone=phone,
            password=password,
            full_name=full_name,
            role=User.ROLE_BARBER,
        )

        salon = None
        if salon_id:
            salon = Salon.objects.filter(pk=salon_id).first()

        barber = Barber.objects.create(
            user=user,
            salon=salon,
            gender=gender if gender in ('male', 'female') else 'male',
            specialization=specialization,
            bio=bio,
            status=Barber.STATUS_PENDING,
        )

        return Response({
            'message': "Ariza yuborildi. Admin tasdiqlashini kuting.",
        }, status=201)


# ---- Barber own panel ----

class BarberMeView(generics.RetrieveUpdateAPIView):
    def get_serializer_class(self):
        if self.request.method in ('PUT', 'PATCH'):
            return BarberUpdateSerializer
        return BarberDetailSerializer

    def get_object(self):
        return self.request.user.barber_profile


class BarberPortfolioManageView(generics.ListCreateAPIView):
    serializer_class = BarberPortfolioSerializer

    def get_queryset(self):
        return BarberPortfolio.objects.filter(barber=self.request.user.barber_profile)

    def perform_create(self, serializer):
        serializer.save(barber=self.request.user.barber_profile)


class BarberPortfolioItemView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = BarberPortfolioSerializer

    def get_queryset(self):
        return BarberPortfolio.objects.filter(barber=self.request.user.barber_profile)


class VacationView(generics.ListCreateAPIView):
    serializer_class = VacationSerializer

    def get_queryset(self):
        return Vacation.objects.filter(barber=self.request.user.barber_profile)

    def perform_create(self, serializer):
        barber = self.request.user.barber_profile
        serializer.save(barber=barber)
        if serializer.validated_data['start_date'] <= __import__('datetime').date.today():
            barber.is_vacation = True
            barber.vacation_until = serializer.validated_data['end_date']
            barber.save()


class CustomerNoteView(generics.ListCreateAPIView):
    serializer_class = CustomerNoteSerializer

    def get_queryset(self):
        return CustomerNote.objects.filter(barber=self.request.user.barber_profile)

    def perform_create(self, serializer):
        serializer.save(barber=self.request.user.barber_profile)


class CustomerNoteDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = CustomerNoteSerializer

    def get_queryset(self):
        return CustomerNote.objects.filter(barber=self.request.user.barber_profile)


class StatusToggleView(APIView):
    def post(self, request):
        barber = request.user.barber_profile
        barber.is_online = not barber.is_online
        barber.save()
        return Response({'is_online': barber.is_online})


# ---- Barber apply (alias for register) ----

class BarberApplyView(BarberRegisterView):
    """Alias endpoint: POST /barbers/apply/ → same as /barbers/register/"""
    pass


# ---- Barber dashboard ----

class BarberDashboardView(APIView):
    """GET /barbers/me/dashboard/ — today stats for the barber's home screen."""

    def get(self, request):
        from apps.bookings.models import Booking
        from django.db.models import Sum, Count

        barber = request.user.barber_profile
        today = date_type.today()

        today_qs = Booking.objects.filter(barber=barber, date=today)
        today_bookings = today_qs.count()
        today_revenue = today_qs.filter(status=Booking.STATUS_COMPLETED).aggregate(s=Sum('final_price'))['s'] or 0

        week_start = today - timedelta(days=today.weekday())
        week_revenue = Booking.objects.filter(
            barber=barber, date__gte=week_start, status=Booking.STATUS_COMPLETED
        ).aggregate(s=Sum('final_price'))['s'] or 0

        month_revenue = Booking.objects.filter(
            barber=barber, date__year=today.year, date__month=today.month, status=Booking.STATUS_COMPLETED
        ).aggregate(s=Sum('final_price'))['s'] or 0

        # Weekly chart (last 7 days)
        chart = []
        days_uz = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya']
        for i in range(6, -1, -1):
            d = today - timedelta(days=i)
            rev = Booking.objects.filter(
                barber=barber, date=d, status=Booking.STATUS_COMPLETED
            ).aggregate(s=Sum('final_price'))['s'] or 0
            chart.append({'day': days_uz[d.weekday()], 'revenue': float(rev)})

        upcoming = Booking.objects.filter(
            barber=barber, date=today,
            status__in=[Booking.STATUS_PENDING, Booking.STATUS_CONFIRMED]
        ).order_by('start_time').count()

        return Response({
            'today_revenue': float(today_revenue),
            'week_revenue': float(week_revenue),
            'month_revenue': float(month_revenue),
            'today_bookings': today_bookings,
            'upcoming_bookings': upcoming,
            'rating': float(barber.rating or 0),
            'is_online': barber.is_online,
            'weekly_chart': chart,
        })


# ---- Barber services (own salon's services) ----

class BarberMeServicesView(APIView):
    """GET /barbers/me/services/?category=<id>  POST /barbers/me/services/"""

    def get(self, request):
        from apps.salons.models import Service
        from apps.salons.serializers import ServiceSerializer
        barber = request.user.barber_profile
        if not barber.salon:
            return Response([])
        qs = Service.objects.filter(salon=barber.salon, is_active=True).select_related('category')
        category_id = request.query_params.get('category')
        if category_id:
            qs = qs.filter(category_id=category_id)
        return Response(ServiceSerializer(qs, many=True, context={'request': request}).data)

    def post(self, request):
        from apps.salons.models import Service, Category
        from apps.salons.serializers import ServiceSerializer
        barber = request.user.barber_profile
        if not barber.salon:
            return Response({'error': 'Siz hech qanday sartaroshxonaga bog\'lanmagan'}, status=400)
        data = request.data
        category_id = data.get('category')
        category = None
        if category_id:
            category = Category.objects.filter(pk=category_id).first()
        service = Service.objects.create(
            salon=barber.salon,
            category=category,
            name=str(data.get('name', '')).strip(),
            price=data.get('price', 0),
            duration=int(data.get('duration', 30)),
            description=str(data.get('description', '')).strip(),
            is_active=True,
        )
        return Response(ServiceSerializer(service, context={'request': request}).data, status=201)


class BarberMeServiceDetailView(APIView):
    """PATCH/DELETE /barbers/me/services/<pk>/"""

    def _get_service(self, request, pk):
        from apps.salons.models import Service
        barber = request.user.barber_profile
        if not barber.salon:
            return None
        return Service.objects.filter(pk=pk, salon=barber.salon).first()

    def patch(self, request, pk):
        from apps.salons.models import Category
        from apps.salons.serializers import ServiceSerializer
        service = self._get_service(request, pk)
        if not service:
            return Response({'error': 'Topilmadi'}, status=404)
        data = request.data
        if 'name' in data:
            service.name = str(data['name']).strip()
        if 'price' in data:
            service.price = data['price']
        if 'duration' in data:
            service.duration = int(data['duration'])
        if 'description' in data:
            service.description = str(data['description']).strip()
        if 'category' in data:
            cat_id = data['category']
            service.category = Category.objects.filter(pk=cat_id).first() if cat_id else None
        service.save()
        return Response(ServiceSerializer(service, context={'request': request}).data)

    def delete(self, request, pk):
        service = self._get_service(request, pk)
        if not service:
            return Response({'error': 'Topilmadi'}, status=404)
        service.delete()
        return Response(status=204)


# ---- Barber schedule (working hours) ----

class BarberScheduleView(APIView):
    """GET/PATCH /barbers/me/schedule/ — view and update this barber's working hours."""

    def get(self, request):
        from apps.salons.models import WorkingHours
        barber = request.user.barber_profile
        # salon=None means barber's own personal schedule (not inherited from salon)
        hours = {h.day_of_week: h for h in WorkingHours.objects.filter(barber=barber, salon=None)}
        schedule = []
        for day in range(7):
            h = hours.get(day)
            schedule.append({
                'day': day,
                'is_working': (not h.is_day_off) if h else (day < 6),
                'start': h.open_time.strftime('%H:%M') if h and h.open_time else '09:00',
                'end': h.close_time.strftime('%H:%M') if h and h.close_time else '19:00',
                'break_start': h.break_start.strftime('%H:%M') if h and h.break_start else None,
                'break_end': h.break_end.strftime('%H:%M') if h and h.break_end else None,
            })
        return Response({
            'vacation_mode': barber.is_vacation,
            'vacation_until': str(barber.vacation_until) if barber.vacation_until else None,
            'schedule': schedule,
        })

    def patch(self, request):
        from apps.salons.models import WorkingHours
        barber = request.user.barber_profile
        vacation_mode = request.data.get('vacation_mode')
        if vacation_mode is not None:
            barber.is_vacation = vacation_mode
            barber.save(update_fields=['is_vacation'])

        schedule = request.data.get('schedule', [])
        for entry in schedule:
            day = entry.get('day')
            if day is None:
                continue
            is_working = entry.get('is_working')
            if is_working is None:
                is_working = True
            WorkingHours.objects.update_or_create(
                barber=barber, day_of_week=day, salon=None,
                defaults={
                    'open_time': entry.get('start') or '09:00',
                    'close_time': entry.get('end') or '19:00',
                    'is_day_off': not bool(is_working),
                    'break_start': entry.get('break_start') or None,
                    'break_end': entry.get('break_end') or None,
                },
            )
        return Response({'message': 'Jadval yangilandi'})


# ---- Barber customers (CRM) ----

class BarberCustomerListView(APIView):
    """GET /barbers/me/customers/ — list unique customers who booked this barber."""

    def get(self, request):
        from apps.bookings.models import Booking
        from django.db.models import Sum, Count, Max
        barber = request.user.barber_profile

        customers = (
            Booking.objects
            .filter(barber=barber, customer__isnull=False)
            .values('customer')
            .annotate(
                total_bookings=Count('id'),
                total_spent=Sum('final_price'),
                last_visit=Max('date'),
            )
            .order_by('-last_visit')
        )

        result = []
        for c in customers:
            from apps.users.models import User
            try:
                user = User.objects.get(pk=c['customer'])
            except User.DoesNotExist:
                continue
            note = CustomerNote.objects.filter(barber=barber, customer=user).first()
            result.append({
                'id': user.pk,
                'full_name': user.full_name,
                'phone': str(user.phone) if user.phone else None,
                'avatar': request.build_absolute_uri(user.avatar.url) if user.avatar else None,
                'total_bookings': c['total_bookings'],
                'total_spent': float(c['total_spent'] or 0),
                'last_visit': str(c['last_visit']) if c['last_visit'] else None,
                'is_vip': (c['total_bookings'] or 0) >= 10,
                'notes': note.note if note else '',
                'booking_history': list(
                    Booking.objects.filter(barber=barber, customer=user)
                    .order_by('-date')
                    .values('id', 'date', 'start_time', 'final_price', 'status')[:5]
                ),
            })
        return Response(result)


class BarberCustomerDetailView(APIView):
    """PATCH /barbers/me/customers/{pk}/ — update note for a customer."""

    def patch(self, request, pk):
        barber = request.user.barber_profile
        from apps.users.models import User
        try:
            customer = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)
        note_text = request.data.get('notes', '')
        note, _ = CustomerNote.objects.get_or_create(barber=barber, customer=customer)
        note.note = note_text
        note.save()
        return Response({'notes': note.note})


# ---- Barber available slots (GET) ----

class BarberSlotsView(APIView):
    """GET /barbers/{pk}/slots/?date=YYYY-MM-DD — available time slots for a barber."""
    permission_classes = [permissions.AllowAny]

    def get(self, request, pk):
        from apps.bookings.models import Booking, WalkInBooking, TimeSlot
        from apps.salons.models import WorkingHours, Service

        try:
            barber = Barber.objects.get(pk=pk, status=Barber.STATUS_APPROVED)
        except Barber.DoesNotExist:
            return Response({'error': 'Sartarosh topilmadi'}, status=404)

        date_str = request.query_params.get('date')
        if not date_str:
            return Response({'error': 'date parametri kerak'}, status=400)
        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response({'error': 'Noto\'g\'ri sana formati (YYYY-MM-DD)'}, status=400)

        day_of_week = target_date.weekday()
        # Prefer barber's personal schedule (salon=None) over salon-inherited hours
        working = (
            barber.working_hours.filter(day_of_week=day_of_week, salon=None, is_day_off=False).first()
            or barber.working_hours.filter(day_of_week=day_of_week, is_day_off=False).exclude(salon=None).first()
        )
        if working is None:
            return Response({'slots': [], 'is_day_off': True, 'message': 'Dam olish kuni'})

        svc_param = request.query_params.get('services', '')
        service_ids = [s.strip() for s in svc_param.split(',') if s.strip()] if svc_param else []
        total_duration = working.slot_duration or 30
        if service_ids:
            services = Service.objects.filter(pk__in=service_ids)
            total_duration = sum(s.duration for s in services) or total_duration

        existing_bookings = Booking.objects.filter(
            barber=barber, date=target_date,
            status__in=[Booking.STATUS_PENDING, Booking.STATUS_CONFIRMED, Booking.STATUS_IN_PROGRESS]
        ).values('start_time', 'end_time')
        walk_ins = WalkInBooking.objects.filter(barber=barber, date=target_date).values('start_time', 'end_time')
        booked_intervals = [(b['start_time'], b['end_time']) for b in list(existing_bookings) + list(walk_ins)]

        # Manual blocks set by the barber (TimeSlot.is_blocked)
        manual_blocked = set(
            ts.start_time for ts in TimeSlot.objects.filter(
                barber=barber, date=target_date, is_blocked=True
            )
        )

        # Break window
        break_start = working.break_start
        break_end = working.break_end

        slots = []
        current = datetime.combine(target_date, working.open_time)
        end_of_day = datetime.combine(target_date, working.close_time)
        slot_end_dt = current + timedelta(minutes=total_duration)

        while slot_end_dt <= end_of_day:
            st = current.time()
            et = slot_end_dt.time()

            if break_start and break_end and not (et <= break_start or st >= break_end):
                status = 'break'
            elif st in manual_blocked:
                status = 'blocked'
            elif any(st < blk_end and et > blk_start for blk_start, blk_end in booked_intervals):
                status = 'booked'
            else:
                status = 'available'

            from django.utils import timezone as tz
            now_local = tz.localtime(tz.now()).replace(tzinfo=None)
            if datetime.combine(target_date, st) > now_local:
                slots.append({
                    'time': st.strftime('%H:%M'),
                    'end_time': et.strftime('%H:%M'),
                    'status': status,
                    'is_available': status == 'available',
                })
            current += timedelta(minutes=working.slot_duration or 30)
            slot_end_dt = current + timedelta(minutes=total_duration)

        return Response({'slots': slots, 'date': date_str, 'is_day_off': False})


# ---- Barber own slots ----

class BarberMeSlotsView(APIView):
    """GET /barbers/me/slots/?date=YYYY-MM-DD — slots with status for the authenticated barber."""

    def get(self, request):
        from apps.bookings.models import Booking, WalkInBooking, TimeSlot
        from apps.salons.models import WorkingHours, Service

        barber = request.user.barber_profile

        date_str = request.query_params.get('date')
        if not date_str:
            return Response({'error': 'date parametri kerak'}, status=400)
        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response({'error': "Noto'g'ri sana formati (YYYY-MM-DD)"}, status=400)

        day_of_week = target_date.weekday()
        working = (
            barber.working_hours.filter(day_of_week=day_of_week, salon=None, is_day_off=False).first()
            or barber.working_hours.filter(day_of_week=day_of_week, is_day_off=False).exclude(salon=None).first()
        )
        if working is None:
            return Response({'slots': [], 'is_day_off': True, 'message': 'Dam olish kuni'})

        slot_duration = working.slot_duration or 30

        # Booked intervals
        booked_intervals = list(Booking.objects.filter(
            barber=barber, date=target_date,
            status__in=[Booking.STATUS_PENDING, Booking.STATUS_CONFIRMED, Booking.STATUS_IN_PROGRESS]
        ).values('start_time', 'end_time'))
        walk_ins = list(WalkInBooking.objects.filter(barber=barber, date=target_date).values('start_time', 'end_time'))
        booked = [(b['start_time'], b['end_time']) for b in booked_intervals + walk_ins]

        # Manual blocks (TimeSlot model)
        manual_blocked = set(
            ts.start_time for ts in TimeSlot.objects.filter(
                barber=barber, date=target_date, is_blocked=True
            )
        )

        # Break interval
        break_start = working.break_start
        break_end = working.break_end

        slots = []
        current = datetime.combine(target_date, working.open_time)
        end_of_day = datetime.combine(target_date, working.close_time)

        while current + timedelta(minutes=slot_duration) <= end_of_day:
            st = current.time()
            et = (current + timedelta(minutes=slot_duration)).time()

            # Determine status
            if break_start and break_end and not (et <= break_start or st >= break_end):
                slot_status = 'break'
            elif st in manual_blocked:
                slot_status = 'blocked'
            elif any(st < blk_end and et > blk_start for blk_start, blk_end in booked):
                slot_status = 'booked'
            else:
                slot_status = 'available'

            slots.append({
                'time': st.strftime('%H:%M'),
                'end_time': et.strftime('%H:%M'),
                'status': slot_status,
                'is_available': slot_status == 'available',
            })
            current += timedelta(minutes=slot_duration)

        return Response({
            'slots': slots,
            'date': date_str,
            'is_day_off': False,
            'working_hours': {
                'start': working.open_time.strftime('%H:%M'),
                'end': working.close_time.strftime('%H:%M'),
                'break_start': working.break_start.strftime('%H:%M') if working.break_start else None,
                'break_end': working.break_end.strftime('%H:%M') if working.break_end else None,
            },
        })


class BarberSlotBlockView(APIView):
    """POST /barbers/me/blocks/ — block or unblock a specific slot."""

    def post(self, request):
        from apps.bookings.models import TimeSlot
        barber = request.user.barber_profile
        date_str = request.data.get('date')
        time_str = request.data.get('time')
        block = request.data.get('block', True)

        if not date_str or not time_str:
            return Response({'error': 'date va time kerak'}, status=400)

        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
            start_time = datetime.strptime(time_str, '%H:%M').time()
        except ValueError:
            return Response({'error': 'Noto\'g\'ri format'}, status=400)

        if block:
            from apps.salons.models import WorkingHours
            from datetime import datetime as dt_
            day_of_week = target_date.weekday()
            wh = WorkingHours.objects.filter(barber=barber, day_of_week=day_of_week, salon=None).first()
            slot_mins = wh.slot_duration if wh else 30
            end_time = (dt_.combine(target_date, start_time) + timedelta(minutes=slot_mins)).time()

            TimeSlot.objects.update_or_create(
                barber=barber, date=target_date, start_time=start_time,
                defaults={
                    'end_time': end_time,
                    'is_blocked': True,
                    'is_available': False,
                    'block_reason': request.data.get('reason', 'Qo\'lda bloklangan'),
                },
            )
            return Response({'message': 'Slot bloklandi', 'blocked': True})
        else:
            TimeSlot.objects.filter(barber=barber, date=target_date, start_time=start_time).delete()
            return Response({'message': 'Blok olib tashlandi', 'blocked': False})


# ---- Admin ----

class AdminBarberListView(generics.ListAPIView):
    queryset = Barber.objects.all().select_related('user', 'salon')
    serializer_class = BarberDetailSerializer
    permission_classes = [permissions.IsAdminUser]
    filterset_fields = ['status', 'salon', 'is_online', 'is_available']
    search_fields = ['user__phone', 'user__full_name', 'specialization']


class AdminBarberVerifyView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk):
        try:
            barber = Barber.objects.get(pk=pk)
        except Barber.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)

        action = request.data.get('action')
        if action == 'approve':
            barber.status = Barber.STATUS_APPROVED
            barber.rejection_reason = ''
            barber.save()
            return Response({'message': f'{barber.user.full_name} tasdiqlandi'})
        elif action == 'reject':
            barber.status = Barber.STATUS_REJECTED
            barber.rejection_reason = request.data.get('reason', '')
            barber.save()
            return Response({'message': f'{barber.user.full_name} rad etildi'})
        return Response({'error': 'Noto\'g\'ri amal'}, status=400)


class AdminBarberUpdateView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def patch(self, request, pk):
        from apps.salons.models import Salon
        try:
            barber = Barber.objects.select_related('user').get(pk=pk)
        except Barber.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)

        user = barber.user
        if 'full_name' in request.data:
            user.full_name = str(request.data['full_name']).strip()
        if 'new_password' in request.data:
            pw = str(request.data['new_password']).strip()
            if len(pw) < 6:
                return Response({'error': "Parol kamida 6 ta belgidan iborat bo'lishi kerak"}, status=400)
            user.set_password(pw)
        user.save()

        if 'salon_id' in request.data:
            sid = request.data['salon_id']
            barber.salon = Salon.objects.filter(pk=sid).first() if sid else None
        if 'specialization' in request.data:
            barber.specialization = request.data['specialization']
        if 'bio' in request.data:
            barber.bio = request.data['bio']
        barber.save()

        return Response(BarberDetailSerializer(barber, context={'request': request}).data)


class AdminBarberDeleteView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def delete(self, request, pk):
        try:
            barber = Barber.objects.select_related('user').get(pk=pk)
        except Barber.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)
        user = barber.user
        name = user.full_name or str(user.phone)
        barber.delete()
        user.delete()
        return Response({'message': f'{name} o\'chirildi'})


class AdminBarberPortfolioView(APIView):
    """
    GET  /barbers/admin/<pk>/portfolio/ — list all portfolio items for a barber
    POST /barbers/admin/<pk>/portfolio/ — add a new portfolio item (multipart)
    """
    permission_classes = [permissions.IsAdminUser]

    def get(self, request, pk):
        items = BarberPortfolio.objects.filter(barber_id=pk).order_by('-created_at')
        return Response(BarberPortfolioSerializer(items, many=True, context={'request': request}).data)

    def post(self, request, pk):
        try:
            barber = Barber.objects.get(pk=pk)
        except Barber.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)
        after = request.FILES.get('after_image')
        if not after:
            return Response({'error': 'after_image majburiy'}, status=400)
        item = BarberPortfolio.objects.create(
            barber=barber,
            after_image=after,
            before_image=request.FILES.get('before_image'),
            caption=request.data.get('caption', ''),
        )
        return Response(BarberPortfolioSerializer(item, context={'request': request}).data, status=201)


class AdminBarberPortfolioItemView(APIView):
    """GET/PATCH/DELETE /barbers/admin/<pk>/portfolio/<item_id>/"""
    permission_classes = [permissions.IsAdminUser]

    def get(self, request, pk, item_id):
        try:
            item = BarberPortfolio.objects.get(pk=item_id, barber_id=pk)
        except BarberPortfolio.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)
        return Response(BarberPortfolioSerializer(item, context={'request': request}).data)

    def patch(self, request, pk, item_id):
        """Approve or reject a portfolio item. Body: {action: 'approve'|'reject', reason: '...'}"""
        try:
            item = BarberPortfolio.objects.get(pk=item_id, barber_id=pk)
        except BarberPortfolio.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)
        action = request.data.get('action')
        if action == 'approve':
            item.status = BarberPortfolio.STATUS_APPROVED
            item.rejection_reason = ''
        elif action == 'reject':
            item.status = BarberPortfolio.STATUS_REJECTED
            item.rejection_reason = request.data.get('reason', '')
        else:
            return Response({'error': "action 'approve' yoki 'reject' bo'lishi kerak"}, status=400)
        item.save(update_fields=['status', 'rejection_reason'])
        return Response(BarberPortfolioSerializer(item, context={'request': request}).data)

    def delete(self, request, pk, item_id):
        try:
            item = BarberPortfolio.objects.get(pk=item_id, barber_id=pk)
        except BarberPortfolio.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)
        if item.after_image:
            item.after_image.delete(save=False)
        if item.before_image:
            item.before_image.delete(save=False)
        item.delete()
        return Response(status=204)


class AdminPendingPortfolioView(APIView):
    """GET /barbers/admin/portfolio/pending/ — all pending portfolio items across all barbers"""
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        items = BarberPortfolio.objects.filter(status='pending').select_related('barber').order_by('-created_at')
        data = []
        for item in items:
            s = BarberPortfolioSerializer(item, context={'request': request}).data
            s['barber_name'] = str(item.barber)
            s['barber_id'] = item.barber_id
            data.append(s)
        return Response(data)
