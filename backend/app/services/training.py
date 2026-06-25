"""
Adaptive Training Plan Service.

Given weak areas from analysis, matches against the exercise library,
applies training principles (weak-point priority, 48h recovery, etc.),
and produces a structured plan.
"""
import logging
from typing import Optional
from datetime import date, timedelta

logger = logging.getLogger(__name__)


# Weak-area → target sub-muscle mapping
WEAK_AREA_MUSCLE_MAP = {
    "upper_chest":    "upper_chest",
    "middle_chest":   "middle_chest",
    "lower_chest":    "lower_chest",
    "inner_chest":    "inner_chest",
    "lats":           "lats",
    "mid_back":       "mid_back",
    "rear_delts":     "rear_delts",
    "front_delts":    "front_delts",
    "side_delts":     "side_delts",
    "biceps":         "biceps",
    "triceps":        "triceps",
    "brachialis":     "brachialis",
    "quads":          "quads",
    "hamstrings":     "hamstrings",
    "glutes":         "glutes",
    "calves":         "calves",
    "abs":            "abs",
    "lower_abs":      "lower_abs",
    "obliques":       "obliques",
    "posterior_chain": "hamstrings",
    "core":           "abs",
}

# Antagonist pairing — ensures balance
ANTAGONIST_PAIRS = {
    "chest":    ["back", "rear_delts"],
    "back":     ["chest"],
    "quads":    ["hamstrings"],
    "hamstrings": ["quads"],
    "biceps":   ["triceps"],
    "triceps":  ["biceps"],
    "abs":      ["posterior_chain"],
}

# Recovery window: muscle groups that shouldn't be hit on consecutive days
RECOVERY_GROUPS = ["chest", "back", "legs", "shoulders", "arms"]


class TrainingPlanService:
    """Generates adaptive training plans based on analysis weak areas."""

    def __init__(self, exercise_library: list[dict]):
        """
        Args:
            exercise_library: list of exercise dicts (loaded from DB)
        """
        self.library = exercise_library

    def generate_plan(
        self,
        weak_areas: list[str],
        fitness_goal: str = "build_muscle",
        fitness_level: str = "intermediate",
        recent_muscle_groups: Optional[list[str]] = None,
    ) -> list[dict]:
        """
        Generate a list of exercises for tomorrow's training.

        Args:
            weak_areas: e.g. ["upper_chest", "rear_delts", "left_arm"]
            fitness_goal: "build_muscle" | "lose_fat" | "maintain"
            fitness_level: "beginner" | "intermediate" | "advanced" | "pro"
            recent_muscle_groups: muscle groups trained in past 48h (to avoid overtraining)

        Returns:
            List of exercise dicts with sets/reps/notes, sorted by priority
        """
        # 1. Map weak areas to target sub-muscles
        target_sub_muscles = []
        for area in weak_areas:
            mapped = WEAK_AREA_MUSCLE_MAP.get(area)
            if mapped:
                target_sub_muscles.append(mapped)
        # Deduplicate
        target_sub_muscles = list(dict.fromkeys(target_sub_muscles))

        # 2. Find matching exercises
        priority_exercises = []
        for ex in self.library:
            if ex.get("target_sub_muscle") in target_sub_muscles:
                priority_exercises.append(ex)

        # 3. If not enough priority exercises, fill with compound basics
        if len(priority_exercises) < 3:
            compounds = [
                ex for ex in self.library
                if ex.get("compound_or_isolation") == "compound"
                and ex not in priority_exercises
            ]
            priority_exercises += compounds[: (5 - len(priority_exercises))]

        # 4. Filter out recently-trained muscle groups (48h rule)
        if recent_muscle_groups:
            priority_exercises = [
                ex for ex in priority_exercises
                if ex.get("target_muscle_group") not in recent_muscle_groups
            ]

        # 5. Sort: weak-area exercises first, then compounds, then isolations
        def sort_key(ex):
            is_weak = ex.get("target_sub_muscle") in target_sub_muscles
            is_compound = ex.get("compound_or_isolation") == "compound"
            return (not is_weak, not is_compound, ex.get("difficulty", 1))

        priority_exercises.sort(key=sort_key)

        # 6. Determine volume based on fitness level
        volume_map = {
            "beginner":     {"exercises": 5, "sets": 3, "reps": "10-12"},
            "intermediate": {"exercises": 6, "sets": 4, "reps": "8-12"},
            "advanced":     {"exercises": 7, "sets": 4, "reps": "6-10"},
            "pro":          {"exercises": 8, "sets": 5, "reps": "5-8"},
        }
        vol = volume_map.get(fitness_level, volume_map["intermediate"])
        selected = priority_exercises[:vol["exercises"]]

        # 7. Ensure antagonist balance: add a pull for every push
        push_groups = {"chest", "front_delts", "quads", "triceps"}
        pull_groups = {"back", "rear_delts", "hamstrings", "biceps"}
        selected_muscles = {ex.get("target_muscle_group") for ex in selected}

        has_push = bool(selected_muscles & push_groups)
        has_pull = bool(selected_muscles & pull_groups)
        if has_push and not has_pull:
            # Add a pull exercise
            pull_ex = next(
                (ex for ex in self.library
                 if ex.get("target_muscle_group") in pull_groups
                 and ex not in selected),
                None
            )
            if pull_ex:
                selected.append(pull_ex)
        elif has_pull and not has_push:
            push_ex = next(
                (ex for ex in self.library
                 if ex.get("target_muscle_group") in push_groups
                 and ex not in selected),
                None
            )
            if push_ex:
                selected.append(push_ex)

        # 8. Format output
        plan_exercises = []
        for i, ex in enumerate(selected):
            is_weak = ex.get("target_sub_muscle") in target_sub_muscles
            plan_exercises.append({
                "exercise_name": ex["name"],
                "target_muscle": ex["target_muscle_group"],
                "sets": vol["sets"] + (1 if is_weak else 0),  # +1 set for weak areas
                "reps": vol["reps"],
                "sort_order": i,
                "notes": self._generate_notes(ex, is_weak),
                "rest_seconds": 60 if ex.get("compound_or_isolation") == "compound" else 45,
            })

        return plan_exercises

    def _generate_notes(self, exercise: dict, is_priority: bool) -> str:
        """Generate exercise-specific coaching notes."""
        parts = []
        if exercise.get("common_mistakes"):
            parts.append(f"注意：{exercise['common_mistakes']}")
        if is_priority:
            parts.append("⭐ 弱项强化，放在第一位完成")
        if exercise.get("description"):
            parts.append(exercise["description"])
        return "；".join(parts) if parts else ""


# Singleton placeholder (populated at startup from DB)
training_plan_service: Optional[TrainingPlanService] = None


async def init_training_service(exercise_library: list[dict]):
    """Initialize the training plan service with exercises from DB."""
    global training_plan_service
    training_plan_service = TrainingPlanService(exercise_library)
