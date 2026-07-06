from telegram import Update
from telegram.ext import ContextTypes
from services.api_client import get_my_bookings, cancel_booking
from keyboards.main_keyboard import my_bookings_keyboard, main_menu_keyboard

async def my_bookings_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    tg_id = query.from_user.id
    bookings = await get_my_bookings(tg_id)
    if not bookings:
        await query.edit_message_text("📅 Sizda hozircha bronlar yo'q.", reply_markup=main_menu_keyboard())
        return 1
    await query.edit_message_text("📅 <b>Mening bronlarim:</b>", parse_mode='HTML', reply_markup=my_bookings_keyboard(bookings))
    return 1

async def cancel_booking_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    booking_id = int(query.data.split('_')[1])
    tg_id = query.from_user.id
    success = await cancel_booking(tg_id, booking_id)
    msg = "✅ Bron bekor qilindi." if success else "❌ Bronni bekor qilib bo'lmadi."
    await query.answer(msg, show_alert=True)
    bookings = await get_my_bookings(tg_id)
    await query.edit_message_reply_markup(my_bookings_keyboard(bookings))
