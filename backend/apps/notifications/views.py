from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Notification, BroadcastNotification
from .serializers import NotificationSerializer, BroadcastNotificationSerializer


class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)


class NotificationMarkReadView(APIView):
    def post(self, request, pk):
        try:
            notif = Notification.objects.get(pk=pk, user=request.user)
            notif.is_read = True
            notif.save()
            return Response({'message': 'O\'qildi'})
        except Notification.DoesNotExist:
            return Response({'error': 'Topilmadi'}, status=404)


class NotificationMarkAllReadView(APIView):
    def post(self, request):
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({'message': 'Barchasi o\'qildi'})


class BroadcastNotificationView(generics.CreateAPIView):
    serializer_class = BroadcastNotificationSerializer
    permission_classes = [permissions.IsAdminUser]

    def perform_create(self, serializer):
        broadcast = serializer.save(sent_by=self.request.user)
        from .tasks import send_broadcast_notification
        send_broadcast_notification.delay(broadcast.pk)
