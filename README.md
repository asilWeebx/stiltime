# StilTime — Beauty & Barbershop Booking Platform

Go'zallik salonlari va sartaroshxonalar uchun to'liq SaaS bron platformasi.

## Tarkib

| Qism | Texnologiya | Port |
|------|------------|------|
| Backend API | Django 4.2 + DRF | 8000 |
| SuperAdmin Panel | React + Vite + Tailwind | 5173 |
| Mijoz ilovasi | Flutter | — |
| Sartarosh ilovasi | Flutter | — |
| Telegram Bot | python-telegram-bot | — |
| Cache / Queue | Redis | 6379 |

## Tez Boshlash

### 1. Backend

```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # .env ni to'ldiring
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

### 2. Admin Panel

```bash
cd admin_panel
npm install
npm run dev          # http://localhost:5173
```

### 3. Celery (alohida terminal)

```bash
cd backend
celery -A stiltime worker --loglevel=info
celery -A stiltime beat --loglevel=info
```

### 4. Telegram Bot

```bash
cd telegram_bot
pip install -r requirements.txt
python bot.py
```

### 5. Flutter Apps

```bash
cd customer_app   # yoki barber_app
flutter pub get
flutter run
```

### Docker (barchasi birga)

```bash
docker-compose up --build
```

---

## API Hujjatlari

- Swagger UI: http://localhost:8000/api/docs/
- ReDoc:       http://localhost:8000/api/redoc/
- Django Admin: http://localhost:8000/admin/

---

## Asosiy API Endpointlar

### Autentifikatsiya
```
POST /api/v1/auth/send-otp/       — OTP yuborish
POST /api/v1/auth/verify-otp/     — OTP tasdiqlash
POST /api/v1/auth/token/refresh/  — Token yangilash
POST /api/v1/auth/logout/         — Chiqish
```

### Salonlar
```
GET  /api/v1/salons/              — Salonlar ro'yxati
GET  /api/v1/salons/{id}/         — Salon detail
GET  /api/v1/salons/categories/   — Kategoriyalar
GET  /api/v1/salons/banners/      — Bannerlar
POST /api/v1/salons/{id}/favorite/— Sevimlilarga qo'shish/olib tashlash
POST /api/v1/salons/coupons/validate/ — Kupon tekshirish
```

### Sartaroshlar
```
GET  /api/v1/barbers/             — Sartaroshlar
GET  /api/v1/barbers/top/         — Top sartaroshlar
GET  /api/v1/barbers/{id}/        — Sartarosh detail
GET  /api/v1/barbers/{id}/portfolio/ — Portfolio
POST /api/v1/barbers/register/    — Sartarosh ro'yxatdan o'tish
POST /api/v1/barbers/me/status/   — Online/Offline toggle
```

### Bronlar
```
POST /api/v1/bookings/slots/      — Bo'sh vaqtlarni olish
POST /api/v1/bookings/create/     — Bron yaratish
GET  /api/v1/bookings/my/         — Mening bronlarim
POST /api/v1/bookings/{id}/cancel/— Bronni bekor qilish
GET  /api/v1/bookings/barber/list/— Sartarosh bronlari
```

### Analytics
```
GET /api/v1/analytics/admin/dashboard/ — Admin dashboard
GET /api/v1/analytics/barber/          — Sartarosh tahlili
```

---

## Ma'lumotlar Bazasi

```
User → OTPCode, CustomerProfile
Salon → Branch, Service, WorkingHours, SalonImage
       PromotionBanner, Coupon, FavoriteSalon
Barber → BarberPortfolio, Vacation, FavoriteBarber, CustomerNote
Booking → WalkInBooking, TimeSlot
Review → (Barber yoki Salon ga bog'liq)
Payment → Transaction
Notification → BroadcastNotification
SubscriptionPlan → Subscription
Region → District
```

---

## Xususiyatlar

### Mijoz Ilovasi
- Telefon + OTP autentifikatsiya
- Salonlar va sartaroshlarni qidirish
- Kategoriya bo'yicha filtrlash
- Sevimlilar (salon + sartarosh)
- Bron oqimi: Xizmat → Sartarosh → Sana → Vaqt → Tasdiqlash
- Bron tarixi va bekor qilish
- Eslatma sozlamalari (15, 30, 45, 60 daqiqa)
- Dark mode + Ko'p til (UZ, RU, EN)

### Sartarosh Ilovasi
- Kunlik/haftalik jadval
- Bevosita mijoz qo'shish (Walk-in)
- CRM tizimi (mijoz eslatmalari, VIP)
- Daromad tahlili (kunlik, haftalik, oylik)
- Portfolio boshqaruvi (before/after)
- Ta'til rejimi
- Online/Offline holat

### SuperAdmin Panel
- Dashboard (statistika, grafik, top salonlar)
- Salonlar CRUD
- Sartarosh tasdiqlash (approve/reject)
- Mijozlar boshqaruvi
- Bronlar monitoring
- Kategoriya va hududlar boshqaruvi
- Banner boshqaruvi
- Push bildirishnoma yuborish
- Hisobotlar va grafikllar

### Telegram Bot
- Inline button asosida bron oqimi
- Salonlar ro'yxati
- Sartaroshlar ro'yxati
- Bron yaratish
- Mening bronlarim
- Bronni bekor qilish

---

## Sozlamalar (.env)

```env
SECRET_KEY=...
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
REDIS_URL=redis://localhost:6379/0
ESKIZ_EMAIL=your@email.com
ESKIZ_PASSWORD=yourpassword
FIREBASE_CREDENTIALS_PATH=/path/to/firebase.json
TELEGRAM_BOT_TOKEN=your-token
```

---

## Loyiha Tuzilishi

```
stiltime/
├── backend/                    # Django backend
│   ├── stiltime/               # Asosiy sozlamalar
│   ├── apps/
│   │   ├── users/              # Foydalanuvchilar, OTP, hududlar
│   │   ├── salons/             # Salonlar, xizmatlar, bannerlar
│   │   ├── barbers/            # Sartaroshlar, portfolio, CRM
│   │   ├── bookings/           # Bronlar, vaqt slotlari
│   │   ├── reviews/            # Sharhlar va reytinglar
│   │   ├── notifications/      # Push bildirishnomalar, WS
│   │   ├── payments/           # To'lovlar, obunalar
│   │   └── analytics/          # Dashboard statistikasi
│   └── manage.py
├── admin_panel/                # React + Vite + Tailwind
│   └── src/
│       ├── api/                # Axios client + API funksiyalar
│       ├── components/         # Layout, common komponentlar
│       ├── pages/              # Barcha sahifalar
│       └── store/              # Zustand state
├── customer_app/               # Flutter mijoz ilovasi
│   └── lib/
│       ├── core/               # Theme, constants, network
│       ├── data/               # Models, repositories
│       ├── presentation/       # Screens, widgets
│       └── providers/          # Riverpod providers
├── barber_app/                 # Flutter sartarosh ilovasi
│   └── lib/
│       └── presentation/screens/
│           ├── dashboard/      # Asosiy dashboard
│           └── customers/      # CRM ekrani
├── telegram_bot/               # Python bot
│   ├── handlers/               # Barcha handler'lar
│   ├── keyboards/              # Inline tugmalar
│   ├── services/               # API client
│   └── bot.py                  # Asosiy bot fayli
├── docker-compose.yml
├── nginx.conf
└── README.md
```
# stiltime
