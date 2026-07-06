from celery import shared_task
from django.utils import timezone


def notify_user(user, title, body, notification_type='booking', data=None):
    """Synchronously create a DB notification and push FCM if token exists."""
    from .models import Notification
    Notification.objects.create(
        user=user, title=title, body=body,
        type=notification_type, data=data or {},
    )
    if user.fcm_token:
        _send_fcm(title, body, [user.fcm_token])


@shared_task
def send_broadcast_notification(broadcast_id):
    from .models import BroadcastNotification, Notification
    from apps.users.models import User
    try:
        broadcast = BroadcastNotification.objects.get(pk=broadcast_id)
    except BroadcastNotification.DoesNotExist:
        return

    if broadcast.target == 'all':
        users = User.objects.filter(is_active=True)
    elif broadcast.target == 'customers':
        users = User.objects.filter(role='customer', is_active=True)
    elif broadcast.target == 'barbers':
        users = User.objects.filter(role='barber', is_active=True)
    else:
        users = User.objects.none()

    notifications = [
        Notification(
            user=u, title=broadcast.title, body=broadcast.body,
            type='promotion', data={'broadcast_id': broadcast_id}
        )
        for u in users
    ]
    Notification.objects.bulk_create(notifications, batch_size=500)

    fcm_tokens = list(users.exclude(fcm_token='').values_list('fcm_token', flat=True))
    if fcm_tokens:
        _send_fcm(broadcast.title, broadcast.body, fcm_tokens)

    broadcast.total_sent = len(notifications)
    broadcast.is_sent = True
    broadcast.sent_at = timezone.now()
    broadcast.save()


def _send_fcm(title, body, tokens):
    try:
        import firebase_admin
        from firebase_admin import messaging
        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            tokens=tokens[:500],
        )
        firebase_admin.messaging.send_each_for_multicast(message)
    except Exception as e:
        print(f"FCM xatosi: {e}")


@shared_task
def send_booking_reminders():
    """
    Runs every minute (via Celery beat).
    Sends reminders at the user's configured time (reminder_minutes) before the booking,
    AND always at 15 minutes before if that window hasn't been sent yet.
    Booking model tracks: reminder_sent (user-configured) + reminder_15m_sent.
    """
    from apps.bookings.models import Booking
    from .models import Notification
    from django.utils import timezone
    from datetime import timedelta, datetime

    now = timezone.now()
    upcoming = Booking.objects.filter(
        status__in=['confirmed'],
    ).select_related('customer', 'barber__user', 'salon')

    for booking in upcoming:
        if not booking.customer:
            continue
        booking_dt = timezone.make_aware(
            datetime.combine(booking.date, booking.start_time)
        )
        if now >= booking_dt:
            continue

        customer = booking.customer
        time_str = booking.start_time.strftime('%H:%M')
        salon_name = booking.salon.name if booking.salon else ''

        # User-configured reminder (15 / 30 / 45 / 60 min)
        if not booking.reminder_sent and customer.notification_reminders:
            reminder_minutes = customer.reminder_minutes or 30
            reminder_time = booking_dt - timedelta(minutes=reminder_minutes)
            if now >= reminder_time:
                Notification.objects.create(
                    user=customer,
                    title=f"Eslatma: {reminder_minutes} daqiqadan so'ng bron 🗓",
                    body=f"{salon_name} — soat {time_str} da {booking.barber.user.full_name}",
                    type='reminder',
                    data={'booking_id': booking.pk},
                )
                if customer.fcm_token:
                    _send_fcm(
                        f"Eslatma — {reminder_minutes} daqiqa qoldi",
                        f"{salon_name}, soat {time_str}",
                        [customer.fcm_token],
                    )
                booking.reminder_sent = True
                booking.save(update_fields=['reminder_sent'])

        # Always send at 15 min before (separate window)
        if not booking.reminder_15m_sent:
            window_15 = booking_dt - timedelta(minutes=15)
            if now >= window_15 and customer.notification_reminders:
                Notification.objects.create(
                    user=customer,
                    title='15 daqiqa qoldi! ⏰',
                    body=f"{salon_name} — {booking.barber.user.full_name} sizi kutmoqda",
                    type='reminder',
                    data={'booking_id': booking.pk},
                )
                if customer.fcm_token:
                    _send_fcm('15 daqiqa qoldi! ⏰', f"{salon_name}, soat {time_str}", [customer.fcm_token])
                booking.reminder_15m_sent = True
                booking.save(update_fields=['reminder_15m_sent'])
