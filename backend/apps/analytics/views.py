from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions
from django.db.models import Sum, Count, Avg
from django.utils import timezone
from datetime import timedelta, date
from apps.bookings.models import Booking
from apps.payments.models import Payment
from apps.users.models import User
from apps.salons.models import Salon
from apps.barbers.models import Barber


class AdminDashboardView(APIView):
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        today = timezone.now().date()
        this_month_start = today.replace(day=1)

        total_salons = Salon.objects.filter(is_active=True).count()
        total_barbers = Barber.objects.filter(status='approved').count()
        total_customers = User.objects.filter(role='customer').count()
        total_bookings = Booking.objects.count()
        today_bookings = Booking.objects.filter(date=today).count()
        pending_barbers = Barber.objects.filter(status='pending').count()

        monthly_revenue = Payment.objects.filter(
            status='paid',
            created_at__date__gte=this_month_start
        ).aggregate(total=Sum('amount'))['total'] or 0

        recent_bookings = Booking.objects.select_related(
            'customer', 'barber__user', 'salon'
        ).order_by('-created_at')[:10]

        from apps.bookings.serializers import BookingSerializer
        bookings_data = BookingSerializer(recent_bookings, many=True, context={'request': request}).data

        last_7_days = []
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            count = Booking.objects.filter(date=day).count()
            revenue = Payment.objects.filter(
                status='paid', created_at__date=day
            ).aggregate(total=Sum('amount'))['total'] or 0
            last_7_days.append({
                'date': day.strftime('%d %b'),
                'bookings': count,
                'revenue': float(revenue),
            })

        top_salons = Salon.objects.filter(is_active=True).order_by('-total_bookings')[:5].values(
            'id', 'name', 'total_bookings', 'rating'
        )

        return Response({
            'stats': {
                'total_salons': total_salons,
                'total_barbers': total_barbers,
                'total_customers': total_customers,
                'total_bookings': total_bookings,
                'today_bookings': today_bookings,
                'pending_barbers': pending_barbers,
                'monthly_revenue': float(monthly_revenue),
            },
            'last_7_days': last_7_days,
            'top_salons': list(top_salons),
            'recent_bookings': bookings_data,
        })


class BarberAnalyticsView(APIView):
    def get(self, request):
        barber = request.user.barber_profile
        today = timezone.now().date()
        week_start = today - timedelta(days=today.weekday())
        month_start = today.replace(day=1)

        bookings_qs = Booking.objects.filter(barber=barber, status=Booking.STATUS_COMPLETED)

        daily = bookings_qs.filter(date=today).aggregate(
            count=Count('id'), revenue=Sum('final_price')
        )
        weekly = bookings_qs.filter(date__gte=week_start).aggregate(
            count=Count('id'), revenue=Sum('final_price')
        )
        monthly = bookings_qs.filter(date__gte=month_start).aggregate(
            count=Count('id'), revenue=Sum('final_price')
        )

        from apps.payments.models import Payment
        cash = Payment.objects.filter(
            booking__barber=barber, status='paid', method='cash'
        ).aggregate(total=Sum('amount'))['total'] or 0
        card = Payment.objects.filter(
            booking__barber=barber, status='paid', method='card'
        ).aggregate(total=Sum('amount'))['total'] or 0

        from apps.salons.models import Service
        popular_services = bookings_qs.values(
            'services__name'
        ).annotate(count=Count('id')).order_by('-count')[:5]

        daily_chart = []
        for i in range(6, -1, -1):
            day = today - timedelta(days=i)
            data = bookings_qs.filter(date=day).aggregate(
                count=Count('id'), revenue=Sum('final_price')
            )
            daily_chart.append({
                'date': day.strftime('%d %b'),
                'bookings': data['count'] or 0,
                'revenue': float(data['revenue'] or 0),
            })

        return Response({
            'daily': {'count': daily['count'] or 0, 'revenue': float(daily['revenue'] or 0)},
            'weekly': {'count': weekly['count'] or 0, 'revenue': float(weekly['revenue'] or 0)},
            'monthly': {'count': monthly['count'] or 0, 'revenue': float(monthly['revenue'] or 0)},
            'payment_methods': {'cash': float(cash), 'card': float(card)},
            'popular_services': list(popular_services),
            'daily_chart': daily_chart,
            'rating': float(barber.rating),
            'total_reviews': barber.total_reviews,
        })
