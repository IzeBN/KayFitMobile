"""
Патч 4: parse_meal_with_openai → parse_meal_with_claude

ЗАМЕНИТЬ текущую функцию parse_meal_with_openai в services.py
И transcribe_audio — заменить Whisper на свой выбор (или оставить Whisper,
он не зависит от GPT/Claude — это отдельная модель)
"""


async def parse_meal_with_claude(text: str):
    """Разбирает текстовое описание приёма пищи на ингредиенты через Claude."""
    key = ANTHROPIC_API_KEY
    if not key:
        return {"error": "ANTHROPIC_API_KEY не задан"}

    raw = (text or "").strip()
    if not raw:
        return {"error": "Введите описание приёма пищи"}

    try:
        client = _get_anthropic_client(key)
        prompt = """Ты — помощник по питанию. Пользователь описал, что съел. Разбери текст на отдельные продукты/блюда.
Верни ТОЛЬКО валидный JSON без markdown и пояснений:
{"items": [{"name": "название на русском", "weight_grams": число в граммах или null}, ...]}
ВАЖНО: name ОБЯЗАТЕЛЬНО только на русском языке (кириллица).
weight_grams — вес порции в граммах; если не указано — оцени типичную порцию (НЕ null).
Типичные порции: тарелка супа 300г, порция каши 250г, стакан молока 250г, яблоко 180г, банан 120г.
Текст пользователя: """

        resp = client.messages.create(
            model="claude-sonnet-4-6",
            max_tokens=500,
            messages=[{"role": "user", "content": prompt + raw}],
        )

        content = resp.content[0].text.strip()
        if content.startswith("```"):
            content = re.sub(r"^```\w*\n?", "", content)
            content = re.sub(r"\n?```\s*$", "", content)

        data = json.loads(content)
        items_in = data.get("items") or []
    except Exception as e:
        return {"error": f"Ошибка Claude: {e}"}

    items_out = []
    total_cal, total_p, total_f, total_c = 0.0, 0.0, 0.0, 0.0
    names_for_summary = []

    search_tasks = []
    item_data = []

    for it in items_in:
        name = (it.get("name") or "").strip()
        if not name:
            continue

        w = it.get("weight_grams")
        if w is not None:
            try:
                w = float(w)
            except (TypeError, ValueError):
                w = 100
        else:
            w = 100

        search_tasks.append(search_food(name))
        item_data.append((name, w))

    search_results = await asyncio.gather(*search_tasks)

    for (name, w), row in zip(item_data, search_results):
        if not row:
            items_out.append({"name": name, "weight_grams": w, "found": False,
                            "calories": 0, "protein": 0, "fat": 0, "carbs": 0})
            continue

        _, food_name, cal, prot, fat, carb = row
        if _has_cyrillic(name) and not _has_cyrillic(food_name):
            food_name = name

        k = w / 100.0
        c, p, f, carb_v = cal * k, prot * k, fat * k, carb * k
        total_cal += c
        total_p += p
        total_f += f
        total_c += carb_v
        names_for_summary.append(name)

        items_out.append({
            "name": food_name,
            "weight_grams": round(w, 0),
            "found": True,
            "calories": round(c, 1),
            "protein": round(p, 1),
            "fat": round(f, 1),
            "carbs": round(carb_v, 1),
        })

    summary_name = ", ".join(names_for_summary[:5])
    if len(names_for_summary) > 5:
        summary_name += " и др."

    return {
        "items": items_out,
        "total": {
            "calories": round(total_cal, 1),
            "protein": round(total_p, 1),
            "fat": round(total_f, 1),
            "carbs": round(total_c, 1),
        },
        "summary_name": summary_name or "Приём пищи",
    }
