import os
import sys
import json
import urllib.request
import urllib.error

# Configurable options
PRIMARY_MODEL = "qwen2.5-coder:3b"
EVALUATOR_MODEL = "qwen2.5-coder:3b"
SCENARIOS_FILE = os.path.join(os.path.dirname(__file__), "test_scenarios.json")

def call_ollama(model, prompt):
    url = "http://localhost:11434/api/generate"
    data = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req) as res:
            response_data = json.loads(res.read().decode("utf-8"))
            return response_data.get("response", "").strip()
    except urllib.error.URLError as e:
        print(f"❌ Error communicating with Ollama: {e}")
        return ""

def score_response(evaluator_model, scenario_name, scenario_expectations, response_text):
    prompt = f"""You are a machine learning QA evaluator. Your job is to grade a Pull Request Review Bot response.
Scenario expectations that the bot SHOULD have caught:
{json.dumps(scenario_expectations, indent=2)}

Here is the Bot's review response:
---
{response_text}
---

Grade the bot's response on three criteria:
1. Coverage: Out of 5, how well did the bot identify all expected issues? (1=missed all, 5=identified all)
2. Actionability: Out of 5, are the suggestions clear and easy to follow? (1=generic/useless, 5=highly concrete)
3. Conciseness: Out of 5, is it clean and free of fluff? (1=extremely wordy/unstructured, 5=perfectly concise)

Output your response strictly as a JSON object, with no markdown code blocks or introduction/conclusion text:
{{
  "coverage": 4.0,
  "actionability": 5.0,
  "conciseness": 4.5,
  "rationale": "Brief one sentence rationale"
}}"""
    res = call_ollama(evaluator_model, prompt)
    # Clean output block if returned in markdown
    if "```json" in res:
        res = res.split("```json")[1].split("```")[0].strip()
    elif "```" in res:
        res = res.split("```")[1].split("```")[0].strip()
    try:
        return json.loads(res)
    except Exception:
        # Fallback parsing or mock score if parsing fails
        return {
            "coverage": 3.0,
            "actionability": 3.0,
            "conciseness": 3.0,
            "rationale": "Failed to parse JSON response from evaluator model."
        }

def main():
    if not os.path.exists(SCENARIOS_FILE):
        print(f"❌ Scenarios file not found at {SCENARIOS_FILE}")
        sys.exit(1)

    with open(SCENARIOS_FILE, "r") as f:
        scenarios = json.load(f)

    # Models we want to compare
    models_to_test = [PRIMARY_MODEL, "llama3.2:3b", "llama3.2:1b"]
    
    print("🤖 Checking available Ollama models...")
    # Ensure all models are pulled (silently pull)
    for model in models_to_test + [EVALUATOR_MODEL]:
        req = urllib.request.Request(
            "http://localhost:11434/api/pull",
            data=json.dumps({"name": model}).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        try:
            urllib.request.urlopen(req)
        except Exception:
            pass # Keep going if offline or if model is already pulled

    results = {}
    for model in models_to_test:
        results[model] = {"coverage": 0.0, "actionability": 0.0, "conciseness": 0.0, "count": 0}

    print("\n🚀 Starting Cross-Model Evaluation...\n")

    for scenario in scenarios:
        name = scenario["name"]
        diff = scenario["diff"]
        expectations = scenario["expectations"]

        print(f"🔹 Scenario: {name}")
        for model in models_to_test:
            prompt = f"""You are a Pull Request reviewer for First-ADE. Review the git diff for:
- Inconsistencies with axioms
- Missing necessary updates to docs
- Missing comments/docstrings

Diff:
{diff}

Output a clean, professional, concise markdown review."""
            
            response = call_ollama(model, prompt)
            if not response:
                print(f"  ⚠️ Model {model} returned no response.")
                continue

            score = score_response(EVALUATOR_MODEL, name, expectations, response)
            
            results[model]["coverage"] += score.get("coverage", 3.0)
            results[model]["actionability"] += score.get("actionability", 3.0)
            results[model]["conciseness"] += score.get("conciseness", 3.0)
            results[model]["count"] += 1
            print(f"  - {model}: Coverage={score.get('coverage')}, Actionability={score.get('actionability')}, Conciseness={score.get('conciseness')}")

    # Calculate averages
    averages = {}
    for model, totals in results.items():
        count = totals["count"] if totals["count"] > 0 else 1
        avg_score = (totals["coverage"] + totals["actionability"] + totals["conciseness"]) / (count * 3.0)
        averages[model] = round(avg_score, 2)

    # Sort models by performance
    sorted_models = sorted(averages.items(), key=lambda x: x[1], reverse=True)
    winner_model, winner_score = sorted_models[0]
    worst_model, worst_score = sorted_models[-1]

    # Write Markdown Benchmark Report
    benchmark_report_path = "MODEL_BENCHMARK.md"
    with open(benchmark_report_path, "w") as f:
        f.write("# 🏆 Cross-Model Evaluation & Quality Benchmark Report\n\n")
        f.write("This automated report grades local LLM performance for First-ADE code & documentation reviews.\n\n")
        f.write("## 📊 Summary Performance Matrix\n\n")
        f.write("| Model | Overall Score (1-5) | Status |\n")
        f.write("| :--- | :---: | :---: |\n")
        for model, score in sorted_models:
            status = "🥇 Winner" if model == winner_model else "🛑 Worst" if model == worst_model else "🥈 Competitor"
            f.write(f"| `{model}` | {score} | {status} |\n")
        
        f.write(f"\n- **Currently Selected Primary Model**: `{PRIMARY_MODEL}`\n")
        f.write(f"- **Evaluator Model**: `{EVALUATOR_MODEL}`\n")

    print(f"\n📁 Benchmark Report written to {benchmark_report_path}")

    # CI Rules: Pass / Warn / Fail
    print("\n⚖️ Evaluating CI Gate Criteria:")
    if PRIMARY_MODEL == winner_model:
        print(f"🟢 PASS: Primary model `{PRIMARY_MODEL}` is the top-performing winner!")
        sys.exit(0)
    elif PRIMARY_MODEL == worst_model:
        print(f"🔴 FAIL: Primary model `{PRIMARY_MODEL}` scored as the worst performer ({averages[PRIMARY_MODEL]}). Upgrade required!")
        sys.exit(1)
    else:
        print(f"🟡 WARN: Primary model `{PRIMARY_MODEL}` is NOT the winner (Winner is `{winner_model}`). Quality degradation warning.")
        # Exit 0 with warning message so execution passes but issues a warning
        sys.exit(0)

if __name__ == "__main__":
    main()
