import asyncio
import logging
from decouple import config
from telegram import Update
from telegram.ext import Application, CommandHandler, CallbackQueryHandler, MessageHandler, ConversationHandler, filters
from handlers.start import start_handler, contact_handler
from handlers.salons import salon_list_handler, salon_detail_handler
from handlers.barbers import barber_list_handler, barber_detail_handler
from handlers.booking import (
    booking_start_handler, service_select_handler,
    date_select_handler, time_select_handler, confirm_handler,
)
from handlers.my_bookings import my_bookings_handler, cancel_booking_handler

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

BOT_TOKEN = '8841494310:AAF_ribBMGi9y0Q0mSr87qByZFW_DlRfH0g'

PHONE, MAIN_MENU, SALON_LIST, SALON_DETAIL, BARBER_LIST, BARBER_DETAIL, SELECT_SERVICE, SELECT_DATE, SELECT_TIME, CONFIRM = range(10)


def main():
    app = Application.builder().token(BOT_TOKEN).build()

    conv_handler = ConversationHandler(
        entry_points=[CommandHandler('start', start_handler)],
        states={
            PHONE: [MessageHandler(filters.CONTACT, contact_handler)],
            MAIN_MENU: [
                CallbackQueryHandler(salon_list_handler, pattern='^salons$'),
                CallbackQueryHandler(barber_list_handler, pattern='^barbers$'),
                CallbackQueryHandler(my_bookings_handler, pattern='^my_bookings$'),
            ],
            SALON_LIST: [CallbackQueryHandler(salon_detail_handler, pattern='^salon_\d+$')],
            BARBER_LIST: [
                CallbackQueryHandler(barber_detail_handler, pattern='^barber_\d+$'),
                CallbackQueryHandler(booking_start_handler, pattern='^book_\d+$'),
            ],
            SELECT_SERVICE: [CallbackQueryHandler(service_select_handler, pattern='^service_')],
            SELECT_DATE: [CallbackQueryHandler(date_select_handler, pattern='^date_')],
            SELECT_TIME: [CallbackQueryHandler(time_select_handler, pattern='^time_')],
            CONFIRM: [
                CallbackQueryHandler(confirm_handler, pattern='^confirm_booking$'),
                CallbackQueryHandler(booking_start_handler, pattern='^cancel_booking$'),
            ],
        },
        fallbacks=[CommandHandler('start', start_handler)],
        allow_reentry=True,
    )

    app.add_handler(conv_handler)
    app.add_handler(CallbackQueryHandler(cancel_booking_handler, pattern='^cancel_\d+$'))

    logger.info("StilTime Bot ishga tushmoqda...")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == '__main__':
    main()
