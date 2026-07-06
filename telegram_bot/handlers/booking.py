from telegram import Update
from telegram.ext import ContextTypes
from datetime import datetime, timedelta
from services.api_client import get_barber, get_available_slots, create_booking
from keyboards.main_keyboard import services_keyboard, dates_keyboard, slots_keyboard, confirm_keyboard

SELECT_SERVICE, SELECT_DATE, SELECT_TIME, CONFIRM = 5, 6, 7, 8


async def booking_start_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    barber_id = int(query.data.split('_')[1])
    tg_id = query.from_user.id
    barber = await get_barber(tg_id, barber_id)

    if not barber:
        await query.edit_message_text("❌ Sartarosh topilmadi")
        return SELECT_SERVICE

    ctx.user_data['barber_id'] = barber_id
    ctx.user_data['barber_name'] = barber.get('user', {}).get('full_name', 'Sartarosh')
    ctx.user_data['selected_services'] = []

    services = barber.get('services', [])[:10]
    ctx.user_data['available_services'] = services

    if not services:
        await query.edit_message_text("❌ Xizmatlar topilmadi")
        return SELECT_SERVICE

    text = f"✂️ <b>{ctx.user_data['barber_name']}</b> uchun xizmat tanlang:\n"
    await query.edit_message_text(text, parse_mode='HTML', reply_markup=services_keyboard(services, []))
    return SELECT_SERVICE


async def service_select_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    if query.data == 'service_done':
        if not ctx.user_data.get('selected_services'):
            await query.answer("Kamida bitta xizmat tanlang!", show_alert=True)
            return SELECT_SERVICE

        # Show date selection
        dates = [(datetime.now() + timedelta(days=i)).strftime('%Y-%m-%d') for i in range(7)]
        date_labels = [(datetime.now() + timedelta(days=i)).strftime('%d %b') for i in range(7)]
        ctx.user_data['dates'] = dates

        text = "📅 <b>Sana tanlang:</b>"
        await query.edit_message_text(text, parse_mode='HTML', reply_markup=dates_keyboard(date_labels))
        return SELECT_DATE

    service_id = int(query.data.split('_')[1])
    selected = ctx.user_data.get('selected_services', [])

    if service_id in selected:
        selected.remove(service_id)
    else:
        selected.append(service_id)

    ctx.user_data['selected_services'] = selected
    services = ctx.user_data.get('available_services', [])
    await query.edit_message_reply_markup(services_keyboard(services, selected))
    return SELECT_SERVICE


async def date_select_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    date_label = query.data.replace('date_', '')
    dates = ctx.user_data.get('dates', [])
    labels = [(datetime.now() + timedelta(days=i)).strftime('%d %b') for i in range(7)]

    if date_label in labels:
        idx = labels.index(date_label)
        selected_date = dates[idx]
    else:
        selected_date = date_label

    ctx.user_data['selected_date'] = selected_date
    barber_id = ctx.user_data['barber_id']
    service_ids = ctx.user_data.get('selected_services', [])
    tg_id = query.from_user.id

    await query.edit_message_text("⏳ Bo'sh vaqtlar tekshirilmoqda...")
    slots = await get_available_slots(tg_id, barber_id, selected_date, service_ids)
    available = [s for s in slots if s['is_available']]

    if not available:
        await query.edit_message_text(f"❌ <b>{date_label}</b> kuni bo'sh vaqt yo'q.\n\nBoshqa sana tanlang.", parse_mode='HTML')
        labels_new = [(datetime.now() + timedelta(days=i)).strftime('%d %b') for i in range(7)]
        await query.edit_message_reply_markup(dates_keyboard(labels_new))
        return SELECT_DATE

    ctx.user_data['available_slots'] = slots
    await query.edit_message_text(
        f"🕐 <b>{date_label}</b> uchun vaqt tanlang:",
        parse_mode='HTML',
        reply_markup=slots_keyboard(slots)
    )
    return SELECT_TIME


async def time_select_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    start_time = query.data.replace('time_', '')
    ctx.user_data['selected_time'] = start_time

    barber_name = ctx.user_data.get('barber_name', 'Sartarosh')
    date = ctx.user_data.get('selected_date', '')
    service_ids = ctx.user_data.get('selected_services', [])
    services = ctx.user_data.get('available_services', [])
    selected_services = [s for s in services if s['id'] in service_ids]
    total_price = sum(float(s['price']) for s in selected_services)
    service_names = ', '.join(s['name'] for s in selected_services)

    text = (
        f"📋 <b>Bron ma'lumotlari:</b>\n\n"
        f"✂️ Sartarosh: <b>{barber_name}</b>\n"
        f"📅 Sana: <b>{date}</b>\n"
        f"🕐 Vaqt: <b>{start_time}</b>\n"
        f"💈 Xizmatlar: <b>{service_names}</b>\n"
        f"💰 Narx: <b>{int(total_price):,} so'm</b>\n\n"
        "Bronni tasdiqlamoqchimisiz?"
    )
    await query.edit_message_text(text, parse_mode='HTML', reply_markup=confirm_keyboard())
    return CONFIRM


async def confirm_handler(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    if query.data == 'cancel_booking':
        await query.edit_message_text("❌ Bron bekor qilindi.", reply_markup=None)
        from keyboards.main_keyboard import main_menu_keyboard
        await query.message.reply_text("🏠 Bosh menyu:", reply_markup=main_menu_keyboard())
        return 1  # MAIN_MENU

    tg_id = query.from_user.id
    booking_data = {
        'barber_id': ctx.user_data['barber_id'],
        'service_ids': ctx.user_data['selected_services'],
        'date': ctx.user_data['selected_date'],
        'start_time': ctx.user_data['selected_time'],
    }

    await query.edit_message_text("⏳ Bron yaratilmoqda...")
    result = await create_booking(tg_id, booking_data)

    if result:
        await query.edit_message_text(
            f"✅ <b>Bron muvaffaqiyatli yaratildi!</b>\n\n"
            f"🔖 Bron ID: <code>#{result['id']}</code>\n"
            f"📅 Sana: {result['date']} {result['start_time']}\n"
            f"💰 Narx: {int(float(result['final_price'])):,} so'm",
            parse_mode='HTML',
        )
    else:
        await query.edit_message_text("❌ Bron yaratishda xatolik yuz berdi. Qayta urinib ko'ring.")

    from keyboards.main_keyboard import main_menu_keyboard
    await query.message.reply_text("🏠 Bosh menyu:", reply_markup=main_menu_keyboard())
    return 1  # MAIN_MENU
