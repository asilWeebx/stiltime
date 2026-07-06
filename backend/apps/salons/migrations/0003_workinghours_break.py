from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('salons', '0002_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='workinghours',
            name='break_start',
            field=models.TimeField(blank=True, null=True, verbose_name='Dam olish boshlanishi'),
        ),
        migrations.AddField(
            model_name='workinghours',
            name='break_end',
            field=models.TimeField(blank=True, null=True, verbose_name='Dam olish tugashi'),
        ),
    ]
