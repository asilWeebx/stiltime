from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('barbers', '0005_add_social_links'),
    ]

    operations = [
        migrations.AddField(
            model_name='barberportfolio',
            name='status',
            field=models.CharField(
                choices=[('pending', 'Kutilmoqda'), ('approved', 'Tasdiqlandi'), ('rejected', 'Rad etildi')],
                default='approved',
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name='barberportfolio',
            name='rejection_reason',
            field=models.CharField(blank=True, max_length=255),
        ),
        # Set existing items to approved so nothing breaks
        migrations.RunSQL(
            "UPDATE barbers_barberportfolio SET status = 'approved' WHERE status IS NULL OR status = '';",
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]
