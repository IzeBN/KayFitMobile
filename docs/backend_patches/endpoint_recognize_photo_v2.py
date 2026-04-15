"""
Патч 3: Обновлённый эндпоинт recognize_photo в main.py

ЗАМЕНИТЬ текущий эндпоинт @app.post("/api/recognize_photo")
"""

from pydantic import BaseModel
from typing import Optional


# ── Обновить модель ──

class RecognizePhotoResponse(BaseModel):
    items: list
    dish_name: str | None = None
    error: str | None = None


# ── Обновить эндпоинт ──

@app.post("/api/recognize_photo", response_model=RecognizePhotoResponse)
async def api_recognize_photo(
    request: Request,
    image: UploadFile = File(...),
    language: str = "ru",
):
    from app.config import BOT_SECRET
    user_id = get_user_id(request)
    if user_id is None:
        bot_secret = request.headers.get("X-Bot-Secret")
        if not BOT_SECRET or bot_secret != BOT_SECRET:
            raise HTTPException(status_code=401, detail="Войдите через бота или приложение")

    if not image.filename:
        raise HTTPException(status_code=400, detail="Отправьте изображение")

    data = await image.read()
    result = await recognize_photo(data, language=language)

    return RecognizePhotoResponse(
        items=result.get("items", []),
        dish_name=result.get("dish_name"),
        error=result.get("error"),
    )


# ── Обновить add_selected — принимать расширенные нутриенты ──

class AddSelectedMealsRequest(BaseModel):
    emotion: str | None = None
    items: list
    dish_name: str | None = None
    meal_type: str | None = None
    date: str | None = None


@app.post("/api/meals/add_selected")
async def api_add_selected_meals(req: AddSelectedMealsRequest, user_id: int = Depends(require_auth)):
    items = req.items or []
    if not items:
        raise HTTPException(status_code=400, detail="Выберите хотя бы один продукт")

    emotion = (req.emotion or "").strip()
    meal_type = req.meal_type or ""
    dish_name = req.dish_name or ""

    added = 0
    for it in items:
        name = (it.get("name") or "").strip()
        if not name:
            continue

        w = float(it.get("weight") or it.get("weight_grams") or 100)
        cal = float(it.get("calories") or 0)
        prot = float(it.get("protein") or 0)
        fat_v = float(it.get("fat") or 0)
        carb = float(it.get("carbs") or 0)

        # Расширенные нутриенты
        fiber = _optional_float(it.get("fiber"))
        sugar = _optional_float(it.get("sugar"))
        sugar_alc = _optional_float(it.get("sugar_alcohols"))
        net_carbs = _optional_float(it.get("net_carbs"))
        sat_fat = _optional_float(it.get("saturated_fat"))
        unsat_fat = _optional_float(it.get("unsaturated_fat"))
        gi = _optional_int(it.get("glycemic_index"))

        display_name = f"{name} ({int(w)} г)"

        await add_meal_v2(
            user_id, display_name, cal, prot, fat_v, carb,
            emotion=emotion,
            meal_type=meal_type,
            dish_name=dish_name,
            fiber=fiber,
            sugar=sugar,
            sugar_alcohols=sugar_alc,
            net_carbs=net_carbs,
            saturated_fat=sat_fat,
            unsaturated_fat=unsat_fat,
            glycemic_index=gi,
            date=req.date,
        )
        added += 1

    return {"added": added}


def _optional_float(val) -> float | None:
    if val is None:
        return None
    try:
        return float(val)
    except (TypeError, ValueError):
        return None


def _optional_int(val) -> int | None:
    if val is None:
        return None
    try:
        return int(float(val))
    except (TypeError, ValueError):
        return None


# ── Новая функция add_meal_v2 (добавить в services.py) ──

async def add_meal_v2(
    user_id: int,
    name: str,
    calories: float,
    protein: float,
    fat: float,
    carbs: float,
    *,
    emotion: str = "",
    meal_type: str = "",
    dish_name: str = "",
    fiber: float | None = None,
    sugar: float | None = None,
    sugar_alcohols: float | None = None,
    net_carbs: float | None = None,
    saturated_fat: float | None = None,
    unsaturated_fat: float | None = None,
    glycemic_index: int | None = None,
    date: str | None = None,
):
    async with (await get_db()).acquire() as conn:
        async with conn.transaction():
            if date:
                await conn.execute(
                    """
                    INSERT INTO meals (
                        user_id, name, calories, protein, fat, carbs,
                        emotion, meal_type, dish_name,
                        fiber, sugar, sugar_alcohols, net_carbs,
                        saturated_fat, unsaturated_fat, glycemic_index,
                        created_at
                    ) VALUES (
                        $1, $2, $3, $4, $5, $6,
                        $7, $8, $9,
                        $10, $11, $12, $13,
                        $14, $15, $16,
                        $17::date + CURRENT_TIME
                    )
                    """,
                    user_id, name, calories, protein, fat, carbs,
                    emotion or "", meal_type, dish_name,
                    fiber, sugar, sugar_alcohols, net_carbs,
                    saturated_fat, unsaturated_fat, glycemic_index,
                    date,
                )
            else:
                await conn.execute(
                    """
                    INSERT INTO meals (
                        user_id, name, calories, protein, fat, carbs,
                        emotion, meal_type, dish_name,
                        fiber, sugar, sugar_alcohols, net_carbs,
                        saturated_fat, unsaturated_fat, glycemic_index,
                        created_at
                    ) VALUES (
                        $1, $2, $3, $4, $5, $6,
                        $7, $8, $9,
                        $10, $11, $12, $13,
                        $14, $15, $16,
                        NOW()
                    )
                    """,
                    user_id, name, calories, protein, fat, carbs,
                    emotion or "", meal_type, dish_name,
                    fiber, sugar, sugar_alcohols, net_carbs,
                    saturated_fat, unsaturated_fat, glycemic_index,
                )
