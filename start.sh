#!/bin/bash
# StilTime — Quick Start Script
# Runs all services in separate terminal processes

set -e
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔═══════════════════════════════════════╗"
echo "║          StilTime Quick Start         ║"
echo "╚═══════════════════════════════════════╝"
echo ""

# ─── Backend ────────────────────────────────
start_backend() {
  echo "▶ Starting Django backend..."
  cd "$ROOT/backend"

  if [ ! -d "venv" ]; then
    echo "  Creating virtualenv..."
    python3 -m venv venv
  fi

  source venv/bin/activate
  pip install -q -r requirements.txt

  if [ ! -f "db.sqlite3" ]; then
    echo "  Running migrations..."
    python manage.py makemigrations users salons barbers bookings reviews notifications payments analytics 2>/dev/null || true
    python manage.py migrate
    echo "  Creating superadmin (phone: +998901234567, no password — OTP)..."
    python manage.py shell -c "
from apps.users.models import User
if not User.objects.filter(phone='+998901234567').exists():
    u = User.objects.create_superuser(phone='+998901234567', password='admin123')
    u.role = 'superadmin'
    u.full_name = 'SuperAdmin'
    u.save()
    print('Superadmin created')
"
  fi

  echo "  Backend starting at http://localhost:8000"
  echo "  API docs: http://localhost:8000/api/docs/"
  echo "  Django admin: http://localhost:8000/admin/"
  python manage.py runserver 2>&1 &
  BACKEND_PID=$!
  echo "  Backend PID: $BACKEND_PID"
}

# ─── Admin Panel ────────────────────────────
start_admin() {
  echo "▶ Starting Admin Panel..."
  cd "$ROOT/admin_panel"

  if [ ! -d "node_modules" ]; then
    echo "  Installing dependencies..."
    npm install --silent
  fi

  echo "  Admin panel starting at http://localhost:5173"
  npm run dev -- --host 2>&1 &
  ADMIN_PID=$!
  echo "  Admin PID: $ADMIN_PID"
}

# ─── Telegram Bot ───────────────────────────
start_bot() {
  if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo "⚠  TELEGRAM_BOT_TOKEN not set, skipping bot"
    return
  fi

  echo "▶ Starting Telegram Bot..."
  cd "$ROOT/telegram_bot"

  if [ ! -d "venv" ]; then
    python3 -m venv venv
  fi
  source venv/bin/activate
  pip install -q -r requirements.txt

  python bot.py 2>&1 &
  BOT_PID=$!
  echo "  Bot PID: $BOT_PID"
}

# ─── Main ───────────────────────────────────
start_backend
sleep 2
start_admin
start_bot

echo ""
echo "═══════════════════════════════════════════"
echo "  StilTime is running!"
echo ""
echo "  Backend API  → http://localhost:8000/api/v1/"
echo "  API Docs     → http://localhost:8000/api/docs/"
echo "  Django Admin → http://localhost:8000/admin/"
echo "  Admin Panel  → http://localhost:5173"
echo ""
echo "  Login: phone +998901234567"
echo "  OTP appears in backend terminal logs"
echo ""
echo "  Press Ctrl+C to stop all services"
echo "═══════════════════════════════════════════"

# Wait for all background jobs
wait
