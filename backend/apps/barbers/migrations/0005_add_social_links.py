from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('barbers', '0004_add_cover_photo'),
    ]

    operations = [
        migrations.AddField(
            model_name='barber',
            name='instagram',
            field=models.CharField(max_length=100, blank=True),
        ),
        migrations.AddField(
            model_name='barber',
            name='telegram',
            field=models.CharField(max_length=100, blank=True),
        ),
    ]
