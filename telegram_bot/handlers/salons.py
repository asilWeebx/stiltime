from telegram import Update
from telegram.ext import ContextTypes
from services.api_client import get_salons, get_salon
from keyboards.main_keyboard import salons_keyboard, main_menu_keyboard

SALON_LIST, SALON_DETAIL = 2, 3

async def salon_list_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    tg_id = query.from_user.id
    data = await get_salons(tg_id)
    salons = data.get('results', data) if isinstance(data, dict) else []
    if not salons:
        await query.edit_message_text("❌ Salonlar topilmadi")
        return SALON_LIST
    await query.edit_message_text("🏪 <b>Salonlar:</b>", parse_mode='HTML', reply_markup=salons_keyboard(salons))
    return SALON_LIST

async def salon_detail_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    salon_id = int(query.data.split('_')[1])
    tg_id = query.from_user.id
    salon = await get_salon(tg_id, salon_id)
    if not salon:
        await query.edit_message_text("❌ Salon topilmadi")
        return SALON_LIST
    rating = salon.get('rating', '—')
    text = (
        f"🏪 <b>{salon['name']}</b>\n\n"
        f"📍 {salon.get('address', '—')}\n"
        f"⭐ Reyting: {rating} ({salon.get('total_reviews', 0)} sharh)\n"
        f"📞 {salon.get('phone', '—')}\n\n"
        f"{salon.get('description', '')}"
    )
    from telegram import InlineKeyboardMarkup, InlineKeyboardButton
    kb = InlineKeyboardMarkup([[InlineKeyboardButton('✂️ Sartaroshlar', callback_data=f'barbers_salon_{salon_id}')], [InlineKeyboardButton('⬅️ Ortga', callback_data='salons')]])
    await query.edit_message_text(text, parse_mode='HTML', reply_markup=kb)
    return SALON_DETAIL
