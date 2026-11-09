import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from summarize_flutter_tests import summarize


def start(test_id=1):
    return {"type": "testStart", "test": {"id": test_id, "name": "test"}}


def done(test_id=1, result="success", **kwargs):
    return {"type": "testDone", "testID": test_id, "result": result, **kwargs}


def stream(*events):
    return "\n".join(json.dumps(event) for event in events)


END = {"type": "done", "success": True}


class FlutterSummaryTest(unittest.TestCase):
    def test_json_lines_with_diagnostics_and_hidden_loader(self):
        result = summarize("download notice\n" + stream(
            ["tool notice"], start(0), done(0, hidden=True),
            start(), done(), END))
        self.assertTrue(result["success"])
        self.assertEqual(result["executed"], 1)
        self.assertEqual(result["passed"], 1)

    def test_top_level_nested_arrays_and_primitive_values(self):
        result = summarize(json.dumps([
            None, True, 7, "notice", [start(), done()], END]))
        self.assertTrue(result["success"])
        self.assertEqual(len(result["diagnostics"]), 4)

    def test_failure_error_and_skip_are_not_execution_errors(self):
        result = summarize(stream(
            start(1), {"type": "error", "testID": 1, "error": "assertion"},
            done(1, "failure"), start(2), done(2, "error"),
            start(3), done(3, skipped=True),
            {"type": "done", "success": False}))
        self.assertEqual(result["executed"], 2)
        self.assertEqual(result["failed"], 2)
        self.assertEqual(result["skipped"], 1)
        self.assertEqual(result["execution_errors"], 0)
        self.assertEqual(result["exit_code"], 1)

    def test_loader_failure_and_abort_do_not_invent_failed_tests(self):
        result = summarize(stream(start(0),
            {"type": "error", "testID": 0, "error": "load failed"},
            done(0, "error", hidden=True),
            {"type": "done", "success": False}))
        self.assertEqual(result["executed"], 0)
        self.assertEqual(result["failed"], 0)
        self.assertEqual(result["execution_errors"], 1)
        self.assertEqual(result["exit_code"], 2)

    def test_no_events_or_only_skipped_is_not_success(self):
        for value in ("", "network failed", "[]", "null", json.dumps(END),
                      stream(start(), done(skipped=True), END)):
            with self.subTest(value=value):
                self.assertFalse(summarize(value)["success"])

    def test_missing_end_or_unfinished_case_is_not_success(self):
        for value in (stream(start(), done()), stream(start(), END)):
            self.assertEqual(summarize(value)["exit_code"], 2)

    def test_malformed_event_payloads_do_not_call_get_on_lists(self):
        for value in (
            {"type": "testStart", "test": []},
            {"type": "testDone", "testID": []},
            {"type": "testDone", "testID": 1, "result": []},
            {"type": "done", "success": []},
        ):
            with self.subTest(value=value):
                result = summarize(stream(value, END))
                self.assertEqual(result["exit_code"], 2)

    def test_unknown_error_id_and_contradictory_success_fail(self):
        for events in (
            (start(), done(), {"type": "error", "testID": []}, END),
            (start(), done(result="failure"), END),
            (done(), END),
        ):
            self.assertFalse(summarize(stream(*events))["success"])

    def test_cli_returns_failure_and_writes_available_counts(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "input").write_text(stream(start(), done()))
            process = subprocess.run([
                sys.executable, str(Path(__file__).with_name(
                    "summarize_flutter_tests.py")),
                str(root / "input"), str(root / "output"),
                "--step-summary", str(root / "summary"),
            ], capture_output=True, text=True)
            self.assertEqual(process.returncode, 2)
            self.assertEqual(json.loads((root / "output").read_text())["passed"], 1)
            self.assertIn("Resumo validado: False", (root / "summary").read_text())


if __name__ == "__main__":
    unittest.main()
