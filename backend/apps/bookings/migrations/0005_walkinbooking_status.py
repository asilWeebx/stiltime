from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bookings', '0004_add_reminder_15m_sent'),
    ]

    operations = [
        migrations.AddField(
            model_name='walkinbooking',
            name='status',
            field=models.CharField(
                choices=[
                    ('confirmed', 'Tasdiqlangan'),
                    ('in_progress', 'Jarayonda'),
                    ('completed', 'Bajarildi'),
                    ('cancelled', 'Bekor'),
                ],
                default='confirmed',
                max_length=20,
            ),
        ),
    ]
