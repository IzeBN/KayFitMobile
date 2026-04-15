"""
Патч 2: search_products — Claude Sonnet вместо GPT + расширенные нутриенты

ЗАМЕНИТЬ: search_products_openai, _suggestion_row, _detect_brand_openai
ПЕРЕИМЕНОВАТЬ: search_products_openai → search_products_claude
"""
import anthropic
import json
import re


def _suggestion_row(
    name: str,
    calories: float,
    protein: float,
    fat: float,
    carbs: float,
    id_val: int = 0,
    per_piece: dict = None,
    fiber: float = 0,
    sugar: float = 0,
    sugar_alcohols: float = 0,
    saturated_fat: float = 0,
    unsaturated_fat: float = 0,
    glycemic_index: int | None = None,
    source: str = "claude",
):
    """Единый формат варианта продукта: КБЖУ + расширенные нутриенты на 100 г."""
    row = {
        "id": id_val,
        "name": name,
        # Базовые на 100г
        "calories": round(float(calories), 1),
        "protein": round(float(protein), 1),
        "fat": round(float(fat), 1),
        "carbs": round(float(carbs), 1),
        # _per_100g алиасы для клиента
        "calories_per_100g": round(float(calories), 1),
        "protein_per_100g": round(float(protein), 1),
        "fat_per_100g": round(float(fat), 1),
        "carbs_per_100g": round(float(carbs), 1),
        # Расширенные
        "fiber_per_100g": round(float(fiber), 1),
        "sugar_per_100g": round(float(sugar), 1),
        "sugar_alcohols_per_100g": round(float(sugar_alcohols), 1),
        "saturated_fat_per_100g": round(float(saturated_fat), 1),
        "unsaturated_fat_per_100g": round(float(unsaturated_fat), 1),
        "glycemic_index": glycemic_index,
        "source": source,
    }
    if per_piece:
        row["per_piece"] = per_piece
    return row


async def _detect_brand_claude(query: str) -> bool:
    """Определяет, указан ли в запросе бренд."""
    key = ANTHROPIC_API_KEY
    if not key or not (query or "").strip():
        return False
    try:
        client = _get_anthropic_client(key)
        resp = client.messages.create(
            model="claude-haiku-4-5-20251001",  # Haiku для дешёвой классификации
            max_tokens=10,
            messages=[{
                "role": "user",
                "content": f'В описании продукта указан конкретный бренд/марка (например "Coca-Cola", "Простоквашино", "Danone")? Ответь только "да" или "нет". Описание: "{query.strip()}"'
            }],
        )
        text = resp.content[0].text.strip().lower()
        return "да" in text or "yes" in text
    except Exception:
        return False


async def search_products_claude(query: str, limit: int = 3) -> list:
    """Поиск продуктов через Claude Sonnet: полный КБЖУ + расширенные нутриенты на 100 г."""
    key = ANTHROPIC_API_KEY
    if not key:
        return []
    q = (query or "").strip()
    if not q:
        return []
    try:
        client = _get_anthropic_client(key)
        prompt = f"""Дай ровно {limit} варианта продукта/блюда по запросу.
Для каждого укажи нутриенты НА 100 г:
- calories, protein, fat, carbs (базовые макросы)
- fiber (клетчатка), sugar (сахар), sugar_alcohols (сахарные спирты, обычно 0)
- saturated_fat (насыщенные жиры), unsaturated_fat (ненасыщенные жиры)
- glycemic_index (гликемический индекс, целое число 0-100, null если неизвестен)

Если продукт поштучный (фрукт, яйцо, булка) — добавь calories_per_piece, protein_per_piece, fat_per_piece, carbs_per_piece.

Точность данных:
- Используй справочные данные (USDA, таблицы Скурихина)
- Для готовых блюд учитывай способ приготовления
- saturated_fat + unsaturated_fat ≤ fat
- fiber + sugar ≤ carbs
- Для соусов типа hot sauce/sriracha: ~50-100 ккал/100г (НЕ 500+)

Верни ТОЛЬКО валидный JSON без markdown:
{{"products": [
  {{
    "name": "название на русском",
    "calories": число, "protein": число, "fat": число, "carbs": число,
    "fiber": число, "sugar": число, "sugar_alcohols": число,
    "saturated_fat": число, "unsaturated_fat": число,
    "glycemic_index": число или null,
    "calories_per_piece": число или null,
    "protein_per_piece": число или null,
    "fat_per_piece": число или null,
    "carbs_per_piece": число или null
  }}
]}}

Запрос: "{q}" """

        resp = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}],
        )
        content = resp.content[0].text.strip()
        if content.startswith("```"):
            content = re.sub(r"^```\w*\n?", "", content)
            content = re.sub(r"\n?```\s*$", "", content)
        data = json.loads(content)
        products = data.get("products") or []
        out = []
        for p in products[:limit]:
            name = (p.get("name") or "").strip()
            if not name:
                continue
            try:
                cal = float(p.get("calories") or 0)
                prot = float(p.get("protein") or 0)
                fat_v = float(p.get("fat") or 0)
                carb = float(p.get("carbs") or 0)
            except (TypeError, ValueError):
                continue

            fiber = _safe_float(p.get("fiber"))
            sugar = _safe_float(p.get("sugar"))
            sugar_alc = _safe_float(p.get("sugar_alcohols"))
            sat_fat = _safe_float(p.get("saturated_fat"))
            unsat_fat = _safe_float(p.get("unsaturated_fat"))
            gi = _safe_int(p.get("glycemic_index"))

            # Санитарная проверка
            if sat_fat + unsat_fat > fat_v * 1.1 and fat_v > 0:
                total_sub = sat_fat + unsat_fat
                sat_fat = sat_fat / total_sub * fat_v
                unsat_fat = unsat_fat / total_sub * fat_v

            per_piece = None
            try:
                c_pp = p.get("calories_per_piece")
                if c_pp is not None and str(c_pp).strip() and str(c_pp).lower() != "null":
                    per_piece = {
                        "calories": float(c_pp),
                        "protein": float(p.get("protein_per_piece") or 0),
                        "fat": float(p.get("fat_per_piece") or 0),
                        "carbs": float(p.get("carbs_per_piece") or 0),
                    }
            except (TypeError, ValueError):
                pass

            out.append(_suggestion_row(
                name, cal, prot, fat_v, carb,
                per_piece=per_piece,
                fiber=fiber,
                sugar=sugar,
                sugar_alcohols=sugar_alc,
                saturated_fat=sat_fat,
                unsaturated_fat=unsat_fat,
                glycemic_index=gi,
                source="claude",
            ))
        return out
    except Exception:
        return []


async def search_products_web(query: str, limit: int = 3) -> list:
    """Поиск продуктов с брендом через веб: Serper + извлечение КБЖУ через Claude."""
    q = (query or "").strip()
    if not q:
        return []
    snippets = await _search_products_serper(q)
    if not snippets:
        return await search_products_claude(q, limit=limit)
    key = ANTHROPIC_API_KEY
    if not key:
        return []
    try:
        client = _get_anthropic_client(key)
        prompt = f"""По результатам веб-поиска извлеки до {limit} вариантов продукта.
Для каждого укажи на 100 г: calories, protein, fat, carbs, fiber, sugar, saturated_fat, unsaturated_fat, glycemic_index.
Верни ТОЛЬКО валидный JSON без markdown:
{{"products": [{{"name": "название на русском", "calories": число, "protein": число, "fat": число, "carbs": число, "fiber": число, "sugar": число, "saturated_fat": число, "unsaturated_fat": число, "glycemic_index": число или null}}, ...]}}
Текст из поиска:
{snippets}
"""
        resp = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=800,
            messages=[{"role": "user", "content": prompt}],
        )
        content = resp.content[0].text.strip()
        if content.startswith("```"):
            content = re.sub(r"^```\w*\n?", "", content)
            content = re.sub(r"\n?```\s*$", "", content)
        data = json.loads(content)
        products = data.get("products") or []
        out = []
        for p in products[:limit]:
            name = (p.get("name") or "").strip()
            if not name:
                continue
            try:
                cal = float(p.get("calories") or 0)
                prot = float(p.get("protein") or 0)
                fat_v = float(p.get("fat") or 0)
                carb = float(p.get("carbs") or 0)
            except (TypeError, ValueError):
                continue
            out.append(_suggestion_row(
                name, cal, prot, fat_v, carb,
                fiber=_safe_float(p.get("fiber")),
                sugar=_safe_float(p.get("sugar")),
                saturated_fat=_safe_float(p.get("saturated_fat")),
                unsaturated_fat=_safe_float(p.get("unsaturated_fat")),
                glycemic_index=_safe_int(p.get("glycemic_index")),
                source="web+claude",
            ))
        return out
    except Exception:
        return await search_products_claude(q, limit=limit)


# Обновить get_product_suggestions — заменить openai на claude
async def get_product_suggestions(query: str, limit: int = 3) -> list:
    q = (query or "").strip()
    if not q:
        return []
    has_brand = await _detect_brand_claude(q)
    if has_brand and SERPER_API_KEY:
        return await search_products_web(q, limit=limit)
    return await search_products_claude(q, limit=limit)


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
