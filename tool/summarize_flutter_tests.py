#!/usr/bin/env python3
"""Summarize Flutter machine JSON without equating runner errors with failures."""
import argparse
import json
from pathlib import Path


def summarize(text):
    starts, finished, errors, endings, issues = {}, {}, [], [], []
    diagnostics = []

    def integer(value):
        return isinstance(value, int) and not isinstance(value, bool)

    def consume(value):
        if isinstance(value, list):
            for item in value:
                consume(item)
            return
        if not isinstance(value, dict):
            diagnostics.append(value)
            return
        kind = value.get("type")
        if kind == "testStart":
            test = value.get("test")
            if not isinstance(test, dict) or not integer(test.get("id")):
                issues.append("Invalid testStart.test object/id")
                return
            starts[test["id"]] = test
        elif kind == "testDone":
            test_id = value.get("testID")
            if (not integer(test_id)
                    or value.get("result") not in ("success", "failure", "error")
                    or not isinstance(value.get("skipped", False), bool)
                    or not isinstance(value.get("hidden", False), bool)):
                issues.append("Invalid testDone fields")
                return
            if test_id in finished and finished[test_id] != value:
                issues.append(f"Conflicting completion for test {test_id}")
            finished[test_id] = value
        elif kind == "error":
            errors.append(value)
        elif kind == "done":
            if not isinstance(value.get("success"), bool):
                issues.append("Invalid done.success")
            else:
                endings.append(value["success"])
        elif kind not in ("start", "suite", "group", "allSuites", "print",
                          "debug", "debuggerPaused"):
            diagnostics.append(value)

    # Accept a complete object/list document as well as the JSON-lines stream.
    try:
        document = json.loads(text)
    except json.JSONDecodeError:
        for line in text.splitlines():
            if not line.strip():
                continue
            try:
                document = json.loads(line)
            except json.JSONDecodeError:
                diagnostics.append(line)
            else:
                consume(document)
    else:
        consume(document)

    counts = {"executed": 0, "passed": 0, "failed": 0, "skipped": 0}
    for test_id, result in finished.items():
        start = starts.get(test_id)
        if start is None:
            issues.append(f"Missing testStart for {test_id}")
        if result.get("hidden", False):
            continue  # Suite loaders are not user test cases.
        if result.get("skipped", False):
            counts["skipped"] += 1
        else:
            counts["executed"] += 1
            counts["passed" if result["result"] == "success" else "failed"] += 1
    for test_id in starts.keys() - finished.keys():
        issues.append(f"Test {test_id} started but did not finish")
    execution_errors = []
    for error in errors:
        test_id = error.get("testID")
        result = finished.get(test_id) if integer(test_id) else None
        if (result is None or result.get("hidden", False)
                or result.get("skipped", False)
                or result.get("result") == "success"):
            execution_errors.append(error)
    if not endings:
        issues.append("Missing final done event")
    if endings and not all(endings) and counts["failed"] == 0:
        issues.append("Runner reported failure without a failed test case")
    if endings and all(endings) and counts["failed"]:
        issues.append("Runner success contradicts failed test cases")
    if counts["executed"] == 0:
        issues.append("No test cases executed")
    valid = not issues and not execution_errors
    return {
        **counts,
        "error_events": len(errors),
        "execution_errors": len(execution_errors),
        "issues": issues,
        "diagnostics": diagnostics,
        "errors": errors,
        "runner_complete": bool(endings),
        "success": valid and counts["failed"] == 0,
        "exit_code": 2 if not valid else (1 if counts["failed"] else 0),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--step-summary", type=Path)
    args = parser.parse_args()
    result = summarize(args.input.read_text())
    args.output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
    message = (
        f"Executados: {result['executed']}; aprovados: {result['passed']}; "
        f"falhados: {result['failed']}; ignorados: {result['skipped']}; "
        f"erros de execução: {result['execution_errors']}. "
        f"Resumo validado: {result['success']}."
    )
    print(message)
    for issue in result["issues"]:
        print(issue)
    for error in result["errors"]:
        print(error.get("error", ""))
        print(error.get("stackTrace", ""))
    if args.step_summary:
        with args.step_summary.open("a") as output:
            output.write("## Resultados Flutter\n\n" + message + "\n\n"
                         "Consultar também os códigos reais em exit-codes.txt.\n")
    return result["exit_code"]


if __name__ == "__main__":
    raise SystemExit(main())
