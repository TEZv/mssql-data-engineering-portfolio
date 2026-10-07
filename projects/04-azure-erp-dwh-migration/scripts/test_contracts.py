import json
import tempfile
import unittest
from pathlib import Path
from validate_extract import manifest

ROOT = Path(__file__).resolve().parents[1]
BATCH = "00000000-0000-0000-0000-000000000001"


class Contracts(unittest.TestCase):
    def test_manifest(self):
        result = manifest(ROOT / "fixtures/initial.csv", BATCH)
        self.assertEqual(result["parameters"]["expected_rows"], "2")
        self.assertEqual(result["parameters"]["expected_amount"], "180.00")
        self.assertEqual(len(result["sha256"]), 64)

    def test_reject_source_errors(self):
        original = (ROOT / "fixtures/initial.csv").read_text()
        variants = [original.replace("O2,", "O1,"), original.replace(",10,", ",0,"),
                    original.replace("100.00", "NaN"), original.replace("100.00", "100.001"),
                    original.replace("2026-10-01", "2026-99-99"), original.splitlines()[0] + "\n"]
        for text in variants:
            with self.subTest(text=text), tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / "bad.csv"
                path.write_text(text)
                with self.assertRaises(ValueError):
                    manifest(path, BATCH)

    def test_adf_graph_and_column_contract(self):
        pipeline = json.loads((ROOT / "adf/pipelines/pl_erp_to_dwh.json").read_text())["properties"]
        datasets = {p.stem: json.loads(p.read_text())["properties"] for p in (ROOT / "adf/datasets").glob("*.json")}
        services = {p.stem for p in (ROOT / "adf/linkedServices").glob("*.json")}
        for dataset in datasets.values():
            self.assertIn(dataset["linkedServiceName"]["referenceName"], services)
        copy, load = pipeline["activities"]
        for reference in copy["inputs"] + copy["outputs"]:
            self.assertIn(reference["referenceName"], datasets)
        self.assertEqual(copy["typeProperties"]["sink"]["upsertSettings"]["keys"], ["BatchId", "SourceOrderId"])
        self.assertEqual(load["dependsOn"][0]["dependencyConditions"], ["Succeeded"])
        self.assertIn(load["linkedServiceName"]["referenceName"], services)
        self.assertEqual(set(load["typeProperties"]["storedProcedureParameters"]), {"BatchId", "ExpectedRows", "ExpectedAmount"})


if __name__ == "__main__":
    unittest.main()
