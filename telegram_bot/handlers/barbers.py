from telegram import Update
from telegram.ext import ContextTypes
from services.api_client import get_barbers, get_barber
from keyboards.main_keyboard import barbers_keyboard, barber_detail_keyboard

BARBER_LIST, BARBER_DETAIL = 4, 3

async def barber_list_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    tg_id = query.from_user.id
    barbers = await get_barbers(tg_id)
    if not barbers:
        await query.edit_message_text("❌ Sartaroshlar topilmadi")
        return BARBER_LIST
    await query.edit_message_text("✂️ <b>Sartaroshlar:</b>", parse_mode='HTML', reply_markup=barbers_keyboard(barbers))
    return BARBER_LIST

async def barber_detail_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    barber_id = int(query.data.split('_')[1])
    tg_id = query.from_user.id
    barber = await get_barber(tg_id, barber_id)
    if not barber:
        await query.edit_message_text("❌ Sartarosh topilmadi")
        return BARBER_LIST
    user = barber.get('user', {})
    text = (
        f"✂️ <b>{user.get('full_name', 'Sartarosh')}</b>\n\n"
        f"💼 Mutaxassislik: {barber.get('specialization', '—')}\n"
        f"📅 Tajriba: {barber.get('experience_years', 0)} yil\n"
        f"⭐ Reyting: {barber.get('rating', '—')} ({barber.get('total_reviews', 0)} sharh)\n\n"
        f"{barber.get('bio', '')}"
    )
    await query.edit_message_text(text, parse_mode='HTML', reply_markup=barber_detail_keyboard(barber_id))
    return BARBER_DETAIL
