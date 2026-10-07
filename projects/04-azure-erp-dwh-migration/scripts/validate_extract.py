"""Produce independently calculated ADF parameters from an immutable ERP CSV."""
import argparse
import csv
import hashlib
import json
from datetime import date
from decimal import Decimal, InvalidOperation
from pathlib import Path
from uuid import UUID

FIELDS = {"SourceOrderId", "OrderDate", "CustomerCode", "ProductCode", "Quantity", "NetAmount", "SourceVersion"}


def manifest(path, batch_id):
    UUID(batch_id)
    payload = Path(path).read_bytes()
    with Path(path).open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if set(reader.fieldnames or []) != FIELDS:
            raise ValueError("Unexpected ERP columns")
        ids, amount, count = set(), Decimal("0.00"), 0
        for row in reader:
            if None in row or any(value is None for value in row.values()):
                raise ValueError("Malformed CSV row")
            for field in ("SourceOrderId", "CustomerCode", "ProductCode"):
                value = row[field]
                if not value.strip() or len(value) > 50 or any(char in value for char in "|\n\r"):
                    raise ValueError("Invalid ERP key")
            if row["SourceOrderId"] in ids:
                raise ValueError("Duplicate order in source batch")
            ids.add(row["SourceOrderId"])
            date.fromisoformat(row["OrderDate"])
            if int(row["Quantity"]) <= 0 or int(row["SourceVersion"]) <= 0:
                raise ValueError("Quantity and version must be positive")
            try:
                net = Decimal(row["NetAmount"])
                if not net.is_finite() or net < 0 or net >= Decimal("10000000000000000") or net.as_tuple().exponent < -2:
                    raise ValueError("Invalid decimal(18,2) amount")
            except InvalidOperation as error:
                raise ValueError("Invalid amount") from error
            amount += net
            count += 1
    if count == 0:
        raise ValueError("Empty source batch")
    return {
        "sha256": hashlib.sha256(payload).hexdigest(),
        "parameters": {"batch_id": str(UUID(batch_id)), "source_file": Path(path).name,
                       "expected_rows": str(count), "expected_amount": f"{amount:.2f}"},
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv")
    parser.add_argument("--batch-id", required=True)
    args = parser.parse_args()
    print(json.dumps(manifest(args.csv, args.batch_id), indent=2))
