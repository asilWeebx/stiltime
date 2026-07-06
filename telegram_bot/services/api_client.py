import httpx
from decouple import config

API_BASE = config('API_BASE_URL', default='http://localhost:8000/api/v1')

_tokens: dict[int, str] = {}


async def _get_headers(user_id: int) -> dict:
    token = _tokens.get(user_id)
    return {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'} if token else {'Content-Type': 'application/json'}


async def send_otp(phone: str) -> bool:
    async with httpx.AsyncClient() as client:
        res = await client.post(f'{API_BASE}/auth/send-otp/', json={'phone': phone})
        return res.status_code == 200


async def verify_otp(phone: str, code: str, telegram_id: int) -> dict | None:
    async with httpx.AsyncClient() as client:
        res = await client.post(f'{API_BASE}/auth/verify-otp/', json={'phone': phone, 'code': code})
        if res.status_code == 200:
            data = res.json()
            _tokens[telegram_id] = data['tokens']['access']
            return data
        return None


async def get_salons(telegram_id: int, page: int = 1) -> dict:
    async with httpx.AsyncClient() as client:
        res = await client.get(f'{API_BASE}/salons/', params={'page': page}, headers=await _get_headers(telegram_id))
        return res.json() if res.status_code == 200 else {}


async def get_salon(telegram_id: int, salon_id: int) -> dict | None:
    async with httpx.AsyncClient() as client:
        res = await client.get(f'{API_BASE}/salons/{salon_id}/', headers=await _get_headers(telegram_id))
        return res.json() if res.status_code == 200 else None


async def get_barbers(telegram_id: int, salon_id: int | None = None) -> list:
    params = {}
    if salon_id:
        params['salon'] = salon_id
    async with httpx.AsyncClient() as client:
        res = await client.get(f'{API_BASE}/barbers/', params=params, headers=await _get_headers(telegram_id))
        data = res.json()
        return data.get('results', data) if isinstance(data, dict) else data


async def get_barber(telegram_id: int, barber_id: int) -> dict | None:
    async with httpx.AsyncClient() as client:
        res = await client.get(f'{API_BASE}/barbers/{barber_id}/', headers=await _get_headers(telegram_id))
        return res.json() if res.status_code == 200 else None


async def get_available_slots(telegram_id: int, barber_id: int, date: str, service_ids: list[int]) -> list:
    async with httpx.AsyncClient() as client:
        res = await client.post(
            f'{API_BASE}/bookings/slots/',
            json={'barber_id': barber_id, 'date': date, 'service_ids': service_ids},
            headers=await _get_headers(telegram_id)
        )
        if res.status_code == 200:
            return res.json().get('slots', [])
        return []


async def create_booking(telegram_id: int, data: dict) -> dict | None:
    async with httpx.AsyncClient() as client:
        res = await client.post(f'{API_BASE}/bookings/create/', json=data, headers=await _get_headers(telegram_id))
        return res.json() if res.status_code == 201 else None


async def get_my_bookings(telegram_id: int) -> list:
    async with httpx.AsyncClient() as client:
        res = await client.get(f'{API_BASE}/bookings/my/', headers=await _get_headers(telegram_id))
        data = res.json()
        return data.get('results', data) if isinstance(data, dict) else []


async def cancel_booking(telegram_id: int, booking_id: int) -> bool:
    async with httpx.AsyncClient() as client:
        res = await client.post(f'{API_BASE}/bookings/{booking_id}/cancel/', headers=await _get_headers(telegram_id))
        return res.status_code == 200
