from django.contrib import admin
from .models import Booking, WalkInBooking, TimeSlot

@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ['id', 'customer', 'barber', 'salon', 'date', 'start_time', 'status', 'final_price', 'source']
    list_filter = ['status', 'source', 'date']
    search_fields = ['customer__phone', 'customer__full_name', 'barber__user__full_name']
    date_hierarchy = 'date'
    readonly_fields = ['created_at', 'updated_at']

@admin.register(WalkInBooking)
class WalkInBookingAdmin(admin.ModelAdmin):
    list_display = ['customer_name', 'customer_phone', 'barber', 'date', 'start_time', 'total_price']
    list_filter = ['date']

admin.site.register(TimeSlot)
