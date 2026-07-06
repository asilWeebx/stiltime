from telegram import InlineKeyboardMarkup, InlineKeyboardButton, ReplyKeyboardMarkup, KeyboardButton


def main_menu_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup([
        [
            InlineKeyboardButton('🏪 Salonlar', callback_data='salons'),
            InlineKeyboardButton('✂️ Sartaroshlar', callback_data='barbers'),
        ],
        [InlineKeyboardButton('📅 Mening bronlarim', callback_data='my_bookings')],
    ])


def contact_keyboard() -> ReplyKeyboardMarkup:
    return ReplyKeyboardMarkup(
        [[KeyboardButton('📱 Telefon raqamni yuborish', request_contact=True)]],
        one_time_keyboard=True,
        resize_keyboard=True,
    )


def salons_keyboard(salons: list, page: int = 1, total: int = 0) -> InlineKeyboardMarkup:
    buttons = [[InlineKeyboardButton(f"🏪 {s['name']}", callback_data=f"salon_{s['id']}")] for s in salons]
    nav = []
    if page > 1:
        nav.append(InlineKeyboardButton('⬅️ Oldingi', callback_data=f'salons_page_{page - 1}'))
    if len(salons) == 10:
        nav.append(InlineKeyboardButton('Keyingi ➡️', callback_data=f'salons_page_{page + 1}'))
    if nav:
        buttons.append(nav)
    buttons.append([InlineKeyboardButton('🏠 Bosh menyu', callback_data='main_menu')])
    return InlineKeyboardMarkup(buttons)


def barbers_keyboard(barbers: list) -> InlineKeyboardMarkup:
    buttons = []
    for b in barbers:
        name = b.get('full_name', b.get('user', {}).get('full_name', 'Sartarosh'))
        rating = b.get('rating', '—')
        buttons.append([InlineKeyboardButton(f"✂️ {name} ⭐{rating}", callback_data=f"barber_{b['id']}")])
    buttons.append([InlineKeyboardButton('🏠 Bosh menyu', callback_data='main_menu')])
    return InlineKeyboardMarkup(buttons)


def barber_detail_keyboard(barber_id: int) -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup([
        [InlineKeyboardButton('📅 Bron qilish', callback_data=f'book_{barber_id}')],
        [InlineKeyboardButton('⬅️ Ortga', callback_data='barbers')],
    ])


def services_keyboard(services: list, selected_ids: list[int]) -> InlineKeyboardMarkup:
    buttons = []
    for s in services:
        check = '✅' if s['id'] in selected_ids else '◻️'
        buttons.append([InlineKeyboardButton(f"{check} {s['name']} — {int(float(s['price']))} so'm", callback_data=f"service_{s['id']}")])
    buttons.append([InlineKeyboardButton('✅ Davom etish', callback_data='service_done')])
    return InlineKeyboardMarkup(buttons)


def dates_keyboard(dates: list[str]) -> InlineKeyboardMarkup:
    buttons = []
    row = []
    for i, d in enumerate(dates):
        row.append(InlineKeyboardButton(d, callback_data=f'date_{d}'))
        if (i + 1) % 3 == 0:
            buttons.append(row)
            row = []
    if row:
        buttons.append(row)
    return InlineKeyboardMarkup(buttons)


def slots_keyboard(slots: list[dict]) -> InlineKeyboardMarkup:
    available = [s for s in slots if s['is_available']]
    buttons = []
    row = []
    for i, s in enumerate(available):
        row.append(InlineKeyboardButton(s['start_time'], callback_data=f"time_{s['start_time']}"))
        if (i + 1) % 4 == 0:
            buttons.append(row)
            row = []
    if row:
        buttons.append(row)
    return InlineKeyboardMarkup(buttons)


def confirm_keyboard() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup([
        [InlineKeyboardButton('✅ Tasdiqlash', callback_data='confirm_booking')],
        [InlineKeyboardButton('❌ Bekor qilish', callback_data='cancel_booking')],
    ])


def my_bookings_keyboard(bookings: list) -> InlineKeyboardMarkup:
    buttons = []
    for b in bookings:
        label = f"#{b['id']} — {b['date']} {b['start_time']} | {b['status']}"
        buttons.append([InlineKeyboardButton(label, callback_data=f"booking_detail_{b['id']}")])
    buttons.append([InlineKeyboardButton('🏠 Bosh menyu', callback_data='main_menu')])
    return InlineKeyboardMarkup(buttons)
