"""
Патч 1: recognize_photo — Claude Sonnet vision + визуальная оценка веса

ЗАМЕНИТЬ текущую функцию recognize_photo в services.py
ДОБАВИТЬ: import anthropic, ANTHROPIC_API_KEY в config.py
"""
import anthropic
import json
import re
import base64
import asyncio


def _get_anthropic_client(api_key: str):
    return anthropic.Anthropic(api_key=api_key)


async def recognize_photo(image_data: bytes, language: str = "ru"):
    """
    Распознаёт еду на фото через Claude Sonnet vision.
    Возвращает структурированный JSON с ингредиентами,
    визуальной оценкой веса и КБЖУ.
    """
    key = ANTHROPIC_API_KEY
    if not key:
        raise ValueError("ANTHROPIC_API_KEY не задан")

    client = _get_anthropic_client(key)
    b64 = base64.standard_b64encode(image_data).decode("ascii")

    # Определяем media type
    media_type = "image/jpeg"
    if image_data[:8] == b'\x89PNG\r\n\x1a\n':
        media_type = "image/png"
    elif image_data[:4] == b'RIFF' and image_data[8:12] == b'WEBP':
        media_type = "image/webp"

    vision_prompt = """Посмотри на изображение.

Если на фото НЕТ еды (графики, документы, скриншоты, пустой стол) — ответь СТРОГО:
{"error": "На изображении нет еды"}

Если еда ЕСТЬ — определи ВСЕ ингредиенты/компоненты блюда и оцени вес КАЖДОГО визуально.

Правила оценки веса:
- Смотри на размер тарелки (стандартная ~25 см)
- Оценивай толщину слоя, высоту горки
- Мясо/рыба: ладонь ≈ 100-120г, кулак ≈ 150-180г
- Рис/каша/пюре: горка на тарелке ≈ 150-250г
- Овощи/салат: большая горсть ≈ 80-100г
- Соус/заправка: столовая ложка ≈ 15-20г
- Хлеб: 1 ломтик ≈ 30-40г
- Яйцо: 1 шт ≈ 55-60г без скорлупы
- НЕ ЗАНИЖАЙ вес — лучше чуть завысить

Также для каждого ингредиента укажи КБЖУ и расширенные нутриенты на 100 г.
Используй справочные данные (USDA, таблицы Скурихина).

Верни ТОЛЬКО валидный JSON без markdown:
{
  "dish_name": "Название блюда",
  "items": [
    {
      "name": "ингредиент на русском",
      "weight_grams": число,
      "calories_per_100g": число,
      "protein_per_100g": число,
      "fat_per_100g": число,
      "carbs_per_100g": число,
      "fiber_per_100g": число,
      "sugar_per_100g": число,
      "saturated_fat_per_100g": число,
      "unsaturated_fat_per_100g": число,
      "glycemic_index": число или null
    }
  ]
}

ВАЖНО:
- name строго на русском
- weight_grams — визуальная оценка (целое число, НЕ null)
- Разделяй сложное блюдо на компоненты (рис отдельно, мясо отдельно, соус отдельно)
- Не пропускай мелкие компоненты (зелень, соусы, специи, хлеб)
- saturated_fat + unsaturated_fat ≤ fat (не больше общего жира)
- fiber ≤ carbs
- Для соусов типа hot sauce/sriracha: ~50-100 ккал/100г (НЕ 500+)"""

    resp = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1500,
        messages=[{
            "role": "user",
            "content": [
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": media_type,
                        "data": b64,
                    },
                },
                {"type": "text", "text": vision_prompt},
            ],
        }],
    )

    content = resp.content[0].text.strip()

    # Парсим JSON
    if content.startswith("```"):
        content = re.sub(r"^```\w*\n?", "", content)
        content = re.sub(r"\n?```\s*$", "", content)

    try:
        vision_data = json.loads(content)
    except json.JSONDecodeError:
        return {"items": [], "error": content if "нет еды" in content.lower() else f"Ошибка парсинга: {content[:200]}"}

    if "error" in vision_data:
        return {"items": [], "error": vision_data["error"]}

    dish_name = vision_data.get("dish_name", "")
    vision_items = vision_data.get("items") or []

    if not vision_items:
        return {"items": [], "error": None, "dish_name": dish_name}

    # Sonnet уже вернул КБЖУ — собираем ответ
    items_out = []
    for item in vision_items:
        name = (item.get("name") or "").strip()
        if not name:
            continue

        w = item.get("weight_grams") or 100

        suggestion = {
            "id": 0,
            "name": name,
            "calories_per_100g": _safe_float(item.get("calories_per_100g")),
            "protein_per_100g": _safe_float(item.get("protein_per_100g")),
            "fat_per_100g": _safe_float(item.get("fat_per_100g")),
            "carbs_per_100g": _safe_float(item.get("carbs_per_100g")),
            "fiber_per_100g": _safe_float(item.get("fiber_per_100g")),
            "sugar_per_100g": _safe_float(item.get("sugar_per_100g")),
            "sugar_alcohols_per_100g": 0.0,
            "saturated_fat_per_100g": _safe_float(item.get("saturated_fat_per_100g")),
            "unsaturated_fat_per_100g": _safe_float(item.get("unsaturated_fat_per_100g")),
            "glycemic_index": _safe_int(item.get("glycemic_index")),
            "source": "claude",
        }

        # Досчитываем абсолютные значения для порции
        k = float(w) / 100.0
        suggestion["calories"] = round(suggestion["calories_per_100g"] * k, 1)
        suggestion["protein"] = round(suggestion["protein_per_100g"] * k, 1)
        suggestion["fat"] = round(suggestion["fat_per_100g"] * k, 1)
        suggestion["carbs"] = round(suggestion["carbs_per_100g"] * k, 1)

        items_out.append({
            "name": name,
            "weight_grams": float(w),
            "suggestions": [suggestion],
            "source": "claude",
        })

    return {
        "items": items_out,
        "dish_name": dish_name,
        "error": None,
    }


def _safe_float(val) -> float:
    if val is None:
        return 0.0
    try:
        return round(float(val), 1)
    except (TypeError, ValueError):
        return 0.0


def _safe_int(val):
    if val is None:
        return None
    try:
        v = str(val).strip().lower()
        if v in ("null", "none", ""):
            return None
        return int(float(v))
    except (TypeError, ValueError):
        return None
