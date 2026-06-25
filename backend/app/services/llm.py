"""
LLM Service — Multi-personality report & plan generation.

Supports (auto-fallback chain):
  1. DeepSeek (deepseek-chat) — primary, ¥1/百万token, best Chinese
  2. Anthropic Claude — secondary
  3. OpenAI GPT-4o — tertiary
  4. Template fallback — when all LLMs are offline

Each provider is lazily initialized and tried in priority order.
"""
import json
import logging
from typing import Optional

from app.config import get_settings
from app.prompts.personalities import build_prompt, build_training_plan_prompt, get_personality_meta

logger = logging.getLogger(__name__)
settings = get_settings()


class LLMService:
    """Handles all LLM calls with multi-provider fallback."""

    def __init__(self):
        self._deepseek_client = None
        self._anthropic_client = None
        self._openai_client = None

    @property
    def _provider_order(self) -> list[str]:
        """Return providers in priority order, skipping those without keys."""
        order = []
        if settings.deepseek_api_key:
            order.append("deepseek")
        if settings.anthropic_api_key:
            order.append("anthropic")
        if settings.openai_api_key:
            order.append("openai")
        if not order:
            order.append("fallback")
        return order

    # ── Public API ───────────────────────────────────────────

    async def generate_report(
        self,
        analysis_json: dict,
        personality: str = "gym_bro",
        photo_type: str = "front",
    ) -> str:
        """Generate a natural-language analysis report (angle-aware)."""
        system_prompt = build_prompt(personality, analysis_json, photo_type=photo_type)
        user_message = "请根据今天的数据生成专业分析报告。只分析当前角度可见的肌群。"

        for provider in self._provider_order:
            try:
                if provider == "deepseek":
                    return await self._call_deepseek(system_prompt, user_message)
                elif provider == "anthropic":
                    return await self._call_claude(system_prompt, user_message)
                elif provider == "openai":
                    return await self._call_openai(system_prompt, user_message)
            except Exception as e:
                logger.warning(f"LLM provider '{provider}' failed: {e}")
                continue

        return self._generate_fallback_report(analysis_json, personality)

    async def generate_report_with_cache(
        self,
        analysis_json: dict,
        personality: str = "gym_bro",
        photo_type: str = "front",
    ) -> dict[str, str]:
        """Generate report + cache alternate personalities for hot-switch."""
        primary_text = await self.generate_report(analysis_json, personality, photo_type=photo_type)

        other_personalities = [
            p for p in ["strict_pro", "gym_bro", "cute_cheerleader",
                         "playful_tsundere", "innocent_rookie"]
            if p != personality
        ]

        alt_cache = {}
        for alt_p in other_personalities:
            try:
                alt_text = await self.generate_report(analysis_json, alt_p, photo_type=photo_type)
                alt_cache[alt_p] = alt_text
            except Exception as e:
                logger.warning(f"Failed to cache personality {alt_p}: {e}")
                alt_cache[alt_p] = ""

        return {
            "primary_personality": personality,
            "primary_text": primary_text,
            "alt_cache": alt_cache,
        }

    async def generate_training_plan(
        self,
        weak_areas: list[str],
        fitness_goal: str = "build_muscle",
        fitness_level: str = "intermediate",
        personality: str = "gym_bro",
        photo_type: str = "front",
        equipment_available: Optional[list[str]] = None,
    ) -> dict:
        """Generate an adaptive training plan (angle-aware)."""
        from app.prompts.personalities import build_training_plan_prompt

        plan_prompt = build_training_plan_prompt(
            personality=personality,
            weak_areas=weak_areas if weak_areas else ["全身均衡发展"],
            fitness_goal=fitness_goal,
            fitness_level=fitness_level,
            equipment="、".join(equipment_available) if equipment_available else "杠铃、哑铃、龙门架、绳索、自重",
            photo_type=photo_type,
        )

        for provider in self._provider_order:
            try:
                if provider == "deepseek":
                    text = await self._call_deepseek(plan_prompt, "请生成明日训练计划（仅返回 JSON，不要 markdown 包裹）")
                elif provider == "anthropic":
                    text = await self._call_claude(plan_prompt, "请生成明日训练计划（仅返回 JSON）")
                elif provider == "openai":
                    text = await self._call_openai(plan_prompt, "请生成明日训练计划（仅返回 JSON）")
                else:
                    continue
                return json.loads(self._extract_json(text))
            except (json.JSONDecodeError, Exception) as e:
                logger.warning(f"Plan generation failed for {provider}: {e}")
                continue

        return self._fallback_plan(weak_areas)

    # ── Private: DeepSeek (primary) ──────────────────────────

    async def _call_deepseek(self, system_prompt: str, user_message: str) -> str:
        """Call DeepSeek API (OpenAI-compatible)."""
        from openai import AsyncOpenAI

        if self._deepseek_client is None:
            self._deepseek_client = AsyncOpenAI(
                api_key=settings.deepseek_api_key,
                base_url=settings.deepseek_base_url,
            )
            logger.info(f"DeepSeek client initialized (model={settings.deepseek_model})")

        response = await self._deepseek_client.chat.completions.create(
            model=settings.deepseek_model,
            max_tokens=1024,
            temperature=0.8,  # Slightly higher for personality variety
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message},
            ],
        )
        return response.choices[0].message.content

    # ── Private: Claude (secondary) ──────────────────────────

    async def _call_claude(self, system_prompt: str, user_message: str) -> str:
        """Call Anthropic Claude API."""
        import anthropic

        if self._anthropic_client is None:
            self._anthropic_client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)

        response = await self._anthropic_client.messages.create(
            model=settings.claude_model,
            max_tokens=800,
            system=system_prompt,
            messages=[{"role": "user", "content": user_message}],
        )
        return response.content[0].text

    # ── Private: OpenAI (tertiary) ───────────────────────────

    async def _call_openai(self, system_prompt: str, user_message: str) -> str:
        """Call OpenAI GPT-4o API."""
        from openai import AsyncOpenAI

        if self._openai_client is None:
            self._openai_client = AsyncOpenAI(api_key=settings.openai_api_key)

        response = await self._openai_client.chat.completions.create(
            model=settings.openai_model,
            max_tokens=800,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message},
            ],
        )
        return response.choices[0].message.content

    # ── Private: Fallbacks ───────────────────────────────────

    def _generate_fallback_report(self, analysis_json: dict, personality: str) -> str:
        """Generate a basic report when all LLMs are unavailable."""
        meta = get_personality_meta(personality)
        progress = analysis_json.get("progress_items", [])
        weaknesses = analysis_json.get("weakness_items", [])
        score = analysis_json.get("overall_score", 70)

        lines = [f"【{meta['name']}教练 · 今日分析】", ""]

        if progress:
            lines.append(f"✓ 进步项 ({len(progress)}项)：")
            for p in progress[:3]:
                lines.append(f"  · {p.get('label', '?')}：+{p.get('change_pct', '?')}%")
        else:
            lines.append("今日各部位保持稳定，无明显变化。")

        if weaknesses:
            lines.append(f"\n⚠ 需要关注 ({len(weaknesses)}项)：")
            for w in weaknesses[:3]:
                lines.append(f"  · {w.get('label', '?')}：{w.get('change_pct', '?')}% → 建议针对性加强")

        lines.append(f"\n【综合评分】{score}/100")
        lines.append("\n[注意：AI 引擎暂时离线，以上为基础数据报告]")
        return "\n".join(lines)

    def _fallback_plan(self, weak_areas: list[str]) -> dict:
        """Return a generic training plan when all LLMs fail."""
        return {
            "warmup": "5分钟跑步机 + 动态拉伸（肩绕环、髋绕环、腿摆）",
            "exercises": [
                {"name": "杠铃深蹲", "target_muscle": "quads", "sets": 4, "reps": "8-12",
                 "notes": "核心收紧，膝盖与脚尖同向", "sort_order": 1},
                {"name": "杠铃卧推", "target_muscle": "chest", "sets": 4, "reps": "8-12",
                 "notes": "肩胛骨后缩，腿驱动", "sort_order": 2},
                {"name": "引体向上", "target_muscle": "lats", "sets": 4, "reps": "8-12",
                 "notes": "控制下放，勿借力摆荡", "sort_order": 3},
                {"name": "杠铃划船", "target_muscle": "mid_back", "sets": 4, "reps": "10",
                 "notes": "俯身45°，杠铃沿大腿拉至腹部", "sort_order": 4},
                {"name": "面拉", "target_muscle": "rear_delts", "sets": 3, "reps": "15",
                 "notes": "外旋肩膀，顶峰收缩", "sort_order": 5},
            ],
            "cooldown": "胸肌拉伸 + 背阔拉伸 + 股四头肌拉伸，各30秒",
            "notes": f"由于 AI 引擎暂时离线，以上为基础模板。建议重点关注：{', '.join(weak_areas[:3])}。",
        }

    @staticmethod
    def _extract_json(text: str) -> str:
        """Extract JSON from LLM output (may be wrapped in markdown fences)."""
        text = text.strip()
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0].strip()
        elif "```" in text:
            text = text.split("```")[1].split("```")[0].strip()
        return text


# Singleton
llm_service = LLMService()
