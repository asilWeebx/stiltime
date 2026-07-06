from telegram import Update
from telegram.ext import ContextTypes
from keyboards.main_keyboard import main_menu_keyboard, contact_keyboard

PHONE, MAIN_MENU = 0, 1


async def start_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    ctx.user_data.clear()

    token = ctx.user_data.get('access_token')
    if token:
        await update.message.reply_text(
            f"✂️ <b>Xush kelibsiz, {user.first_name}!</b>\n\nQuyidagi menyudan foydalaning:",
            parse_mode='HTML',
            reply_markup=main_menu_keyboard(),
        )
        return MAIN_MENU

    await update.message.reply_text(
        f"👋 <b>Salom, {user.first_name}!</b>\n\n"
        "StilTime — sartaroshxona va go'zallik salonlari uchun bron platformasi.\n\n"
        "📱 Davom etish uchun telefon raqamingizni yuboring:",
        parse_mode='HTML',
        reply_markup=contact_keyboard(),
    )
    return PHONE


async def contact_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    contact = update.message.contact
    phone = contact.phone_number
    if not phone.startswith('+'):
        phone = '+' + phone

    ctx.user_data['phone'] = phone

    from services.api_client import send_otp
    sent = await send_otp(phone)

    if sent:
        await update.message.reply_text(
            f"📨 <b>{phone}</b> raqamiga OTP kod yuborildi.\n\n"
            "Kodni kiriting (masalan: <code>123456</code>):",
            parse_mode='HTML',
        )
        ctx.user_data['awaiting_otp'] = True
    else:
        await update.message.reply_text("❌ Xatolik yuz berdi. Qayta urinib ko'ring.")

    return PHONE
