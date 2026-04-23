import os
from dotenv import load_dotenv

# ==============================
# LOAD .env FROM ROOT
# ==============================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV_PATH = os.path.join(BASE_DIR, ".env")

load_dotenv(ENV_PATH)

API_KEY = os.getenv("GEMINI_API_KEY")

if not API_KEY:
    raise ValueError("❌ GEMINI_API_KEY not found in .env file")

# ==============================
# GEMINI SETUP
# ==============================
from google import genai
from google.genai import types

client = genai.Client(api_key=API_KEY)

PRO_MODEL   = "gemini-2.0-flash"
FLASH_MODEL = "gemini-2.0-flash-lite"

# ==============================
# PROMPT: Single Report
# ==============================
def build_single_report_prompt(report_text: str) -> str:
    return f"""
You are a clinical assistant summarizing a lab report for a patient.

For each parameter listed:
- State its name
- State whether it is normal, low, or high
- Include the numeric value and unit
- Use a consistent format like:
  Hemoglobin: slightly low (10.2 g/dL)

Then provide a 2-line overall health summary.

If a parameter is within normal range, say "normal" and include the value.

Lab Report:
{report_text}
""".strip()


# ==============================
# PROMPT: Parameter-by-Parameter Trend
# ==============================
def build_trend_prompt(trend_text: str) -> str:
    return f"""
You are a clinical assistant reviewing lab results from multiple reports for the same patient.

Output a parameter-by-parameter trend breakdown. Use EXACTLY this format for every parameter:

<Parameter Name>:
  • <Report Label>: <value> — <normal / low / high>
  • <Report Label>: <value> — <normal / low / high>
  → Trend: <one sentence describing the trend: stable / improving / worsening / fluctuating / consistently normal, with specific detail>

Strict rules:
- One block per parameter, separated by a blank line.
- Every report that measured this parameter must appear as its own bullet line.
- The "→ Trend:" line must be specific — e.g. "dropped in Report 2, then recovered by Report 3" or "consistently elevated across all reports".
- Do NOT write any introduction, conclusion, or overall health summary. Parameter blocks only.
- Use plain, patient-friendly language. No medical jargon.

Lab Parameter Trends:
{trend_text}
""".strip()


# ==============================
# HELPER: Call Gemini safely
# ==============================
def _call_model(model_name: str, prompt: str) -> str | None:
    try:
        response = client.models.generate_content(
            model=model_name,
            contents=prompt,
            config=types.GenerateContentConfig(
                max_output_tokens=1024,
                temperature=0.2,
            ),
        )
        text = response.text.strip() if response and response.text else ""
        return text if text else None
    except Exception as e:
        print(f"⚠️ Model {model_name} failed: {e}")
        return None


# ==============================
# SINGLE REPORT SUMMARY
# (existing function — unchanged interface)
# ==============================
def generate_summary(parameters: dict, abnormal: dict) -> str:
    """
    Summarize a single lab report.

    Args:
        parameters : { param_name: value_string }
                     e.g. {"Hemoglobin": "10.2 g/dL", "WBC": "6.5 K/uL"}
        abnormal   : { param_name: "LOW" | "HIGH" }  — omit key if normal
                     e.g. {"Hemoglobin": "LOW"}

    Returns:
        Human-readable summary string.
    """
    if not parameters:
        return (
            "⚠️ No lab parameters could be extracted from the report. "
            "Please ensure the file is a clear, readable PDF or image."
        )

    abnormal = abnormal or {}

    report_lines = [
        f"{param}: {value} ({abnormal.get(param, 'NORMAL')})"
        for param, value in parameters.items()
    ]
    prompt = build_single_report_prompt("\n".join(report_lines))

    for model in (PRO_MODEL, FLASH_MODEL):
        result = _call_model(model, prompt)
        if result:
            return result

    print("⚠️ Both Gemini models failed — using rule-based fallback")
    return _rule_based_single_summary(parameters, abnormal)


# ==============================
# MULTI-REPORT ANALYSIS  ← NEW
# ==============================
def generate_multi_report_summary(reports: list[dict]) -> dict:
    """
    Analyze multiple lab reports: individual summaries + parameter-by-parameter trend.

    Args:
        reports: list of dicts, each containing:
            {
                "label"     : str   — display name, e.g. "January CBC" or "Report 1"
                "parameters": dict  — { param_name: value_string }
                "abnormal"  : dict  — { param_name: "LOW" | "HIGH" }  (optional)
            }

    Returns:
        {
            "per_report"   : [ {"label": str, "summary": str}, ... ],
            "trend_summary": str   — parameter-by-parameter trend text
        }

    Usage example:
        reports = [
            {
                "label": "January CBC",
                "parameters": {"Hemoglobin": "10.2 g/dL", "WBC": "6.5 K/uL"},
                "abnormal": {"Hemoglobin": "LOW"},
            },
            {
                "label": "April CBC",
                "parameters": {"Hemoglobin": "12.1 g/dL", "WBC": "7.0 K/uL"},
                "abnormal": {},
            },
        ]
        result = generate_multi_report_summary(reports)
        print(format_multi_report_output(result))
    """
    if not reports:
        return {
            "per_report": [],
            "trend_summary": "⚠️ No reports provided for analysis.",
        }

    # ── Step 1: Summarize each report individually ──────────────────────────
    per_report_results = []
    for i, report in enumerate(reports):
        label      = report.get("label") or f"Report {i + 1}"
        parameters = report.get("parameters", {})
        abnormal   = report.get("abnormal", {})

        print(f"🔄 Summarizing: {label} ...")
        summary = generate_summary(parameters, abnormal)
        per_report_results.append({"label": label, "summary": summary})
        print(f"✅ Done: {label}")

    # ── Step 2: Collect per-parameter values across all reports ─────────────
    # all_params = { param_name: [ "January CBC: 10.2 g/dL (LOW)", ... ] }
    all_params: dict[str, list[str]] = {}

    for report in reports:
        label      = report.get("label", "Unknown")
        parameters = report.get("parameters", {})
        abnormal   = report.get("abnormal", {})

        for param, value in parameters.items():
            status = abnormal.get(param, "NORMAL").upper()
            entry  = f"{label}: {value} ({status})"
            all_params.setdefault(param, []).append(entry)

    # ── Step 3: Split params into "has trend" vs "single report only" ────────
    trend_blocks       = []   # params appearing in ≥2 reports
    single_only_params = []   # params appearing in only 1 report

    for param, entries in all_params.items():
        if len(entries) >= 2:
            bullet_lines = "\n  ".join(entries)
            trend_blocks.append(f"{param}:\n  {bullet_lines}")
        else:
            single_only_params.append(f"  {param}: {entries[0]}")

    # ── Step 4: Generate AI trend summary ────────────────────────────────────
    if trend_blocks:
        trend_input   = "\n\n".join(trend_blocks)
        trend_summary = _generate_trend_summary(trend_input)
    else:
        trend_summary = (
            "ℹ️ No parameters were shared across 2 or more reports. "
            "Trend analysis requires the same parameter to appear in at least 2 reports."
        )

    # Append single-report-only params as a footnote
    if single_only_params:
        trend_summary += (
            "\n\n📋 Parameters found in only one report (no trend possible):\n"
            + "\n".join(single_only_params)
        )

    return {
        "per_report":    per_report_results,
        "trend_summary": trend_summary,
    }


def _generate_trend_summary(trend_input: str) -> str:
    """Call Gemini for trend analysis. Falls back to rule-based formatting."""
    prompt = build_trend_prompt(trend_input)

    for model in (PRO_MODEL, FLASH_MODEL):
        result = _call_model(model, prompt)
        if result:
            return result

    # Rule-based fallback: reformat raw input into the same bullet style
    print("⚠️ Both Gemini models failed — using rule-based trend fallback")
    blocks = []
    for block in trend_input.strip().split("\n\n"):
        lines = [l.strip() for l in block.strip().splitlines() if l.strip()]
        if not lines:
            continue
        param_name  = lines[0].rstrip(":")
        entry_lines = "\n".join(f"  • {l}" for l in lines[1:])
        blocks.append(
            f"{param_name}:\n{entry_lines}\n"
            f"  → Trend: AI unavailable — please review values above manually."
        )
    return "\n\n".join(blocks)


# ==============================
# RULE-BASED SINGLE SUMMARY (fallback)
# ==============================
def _rule_based_single_summary(parameters: dict, abnormal: dict) -> str:
    lines          = []
    abnormal_flags = []

    for param, value in parameters.items():
        status = abnormal.get(param, "NORMAL").upper()
        if status == "LOW":
            lines.append(f"{param}: slightly low ({value})")
            abnormal_flags.append(f"{param} is low")
        elif status == "HIGH":
            lines.append(f"{param}: slightly elevated ({value})")
            abnormal_flags.append(f"{param} is high")
        else:
            lines.append(f"{param}: normal ({value})")

    overall = (
        f"Note: {', '.join(abnormal_flags)}. Please consult your doctor for interpretation."
        if abnormal_flags
        else "All parameters appear to be within normal range."
    )
    return "\n".join(lines) + f"\n\n{overall}"


# ==============================
# OUTPUT FORMATTER
# ==============================
def format_multi_report_output(result: dict) -> str:
    """
    Formats generate_multi_report_summary() output into a readable string.
    Pass this to print(), a UI text area, or a PDF renderer.
    """
    lines = []

    lines.append("=" * 60)
    lines.append("📋  INDIVIDUAL REPORT SUMMARIES")
    lines.append("=" * 60)

    for item in result["per_report"]:
        lines.append(f"\n🔹 {item['label']}")
        lines.append("-" * 40)
        lines.append(item["summary"])

    lines.append("\n" + "=" * 60)
    lines.append("📈  PARAMETER-BY-PARAMETER TREND ANALYSIS")
    lines.append("=" * 60)
    lines.append(result["trend_summary"])

    return "\n".join(lines)