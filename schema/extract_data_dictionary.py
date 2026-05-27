#!/usr/bin/env python3
"""Extract a CWMS_20 data dictionary (two CSVs) from the build SQL files.

Produces:
    <out-dir>/cwms_20_tables.csv  -- one row per table
    <out-dir>/cwms_20_columns.csv -- one row per column

Descriptions are pulled from the COMMENT ON TABLE / COMMENT ON COLUMN
statements in the SQL. When no comment exists, a description is guessed
from the identifier name.

Usage:
    python3 extract_data_dictionary.py [--src DIR] [--out DIR] [--schema NAME]

Defaults assume the script lives in <repo>/schema/, with SQL under
<repo>/schema/src/ and CSVs written into <repo>/schema/.
"""

import argparse
import csv
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_SRC = SCRIPT_DIR / "src"
DEFAULT_OUT = SCRIPT_DIR
DEFAULT_SCHEMA = "CWMS_20"

# Files sourced by buildCWMS_DB.sql that contain static CREATE TABLE statements.
# (Excludes package bodies which create tables dynamically, updateScripts, and tests.)
SCHEMA_FILES = [
    "py_BuildCwms.sql",
    "cwms/at_schema.sql",
    "cwms/rowcps_schema.sql",
    "cwms/at_schema_crrel.sql",
    "cwms/at_schema_alarm.sql",
    "cwms/at_schema_screening.sql",
    "cwms/at_schema_dss_xchg.sql",
    "cwms/at_schema_msg.sql",
    "cwms/at_schema_rating.sql",
    "cwms/at_schema_tsv.sql",
    "cwms/at_schema_tr.sql",
    "cwms/at_schema_sec_2.sql",
    "cwms/at_schema_sec.sql",
    "cwms/at_schema_cma.sql",
    "cwms/at_schema_2.sql",
    "cwms/at_schema_tsv_dqu.sql",
]


def build_file_list(src_root):
    files = list(SCHEMA_FILES)
    tables_dir = src_root / "cwms" / "tables"
    if tables_dir.is_dir():
        for f in sorted(tables_dir.glob("*.sql")):
            rel = str(f.relative_to(src_root))
            if rel not in files:
                files.append(rel)
    return files


# ------------------------- Tokenization helpers -------------------------

def strip_comments(text):
    # Remove /* ... */ multi-line comments
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    # Remove -- line comments
    text = re.sub(r"--[^\n]*", "", text)
    return text


def find_matching_paren(text, open_idx):
    """Given index of '(' return index of matching ')'."""
    depth = 0
    i = open_idx
    in_str = False
    while i < len(text):
        c = text[i]
        if c == "'":
            # toggle but handle '' escape
            if in_str and i + 1 < len(text) and text[i + 1] == "'":
                i += 2
                continue
            in_str = not in_str
        elif not in_str:
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    return -1


def clean_id(s):
    return s.strip().strip('"').strip().upper()


def split_top_commas(body):
    """Split body of CREATE TABLE on top-level commas."""
    parts = []
    depth = 0
    cur = []
    in_str = False
    i = 0
    while i < len(body):
        c = body[i]
        if c == "'":
            if in_str and i + 1 < len(body) and body[i + 1] == "'":
                cur.append("''")
                i += 2
                continue
            in_str = not in_str
            cur.append(c)
        elif not in_str:
            if c == "(":
                depth += 1
                cur.append(c)
            elif c == ")":
                depth -= 1
                cur.append(c)
            elif c == "," and depth == 0:
                parts.append("".join(cur).strip())
                cur = []
            else:
                cur.append(c)
        else:
            cur.append(c)
        i += 1
    if cur:
        last = "".join(cur).strip()
        if last:
            parts.append(last)
    return parts


# ------------------------- Column parsing -------------------------

CONSTRAINT_LEAD = re.compile(
    r"^(constraint\b|primary\s+key\b|unique\b|foreign\s+key\b|check\b|"
    r"partition\b|subpartition\b|using\s+index\b|lob\b|nested\s+table\b|"
    r"organization\b|tablespace\b|pctfree\b|pctused\b|initrans\b|maxtrans\b|"
    r"storage\b|logging\b|nocompress\b|compress\b|noparallel\b|parallel\b|"
    r"cache\b|nocache\b|enable\b|disable\b|monitoring\b|nomonitoring\b)",
    re.I,
)

# Data type pattern: identifier optionally followed by (n[,m] [byte|char]) or "with time zone" etc.
TYPE_PATTERN = re.compile(
    r"""
    ^(?P<type>
        timestamp(?:\s*\(\s*\d+\s*\))?(?:\s+with(?:\s+local)?\s+time\s+zone)?
        | interval\s+\w+(?:\s*\(\s*\d+\s*\))?\s+to\s+\w+(?:\s*\(\s*\d+\s*\))?
        | long\s+raw
        | double\s+precision
        | character\s+varying(?:\s*\(\s*\d+\s*\))?
        | \w+(?:\s*\(\s*\d+(?:\s*,\s*\d+)?(?:\s+(?:byte|char))?\s*\))?
    )
    """,
    re.I | re.X,
)

TEXT_TYPES = {"VARCHAR", "VARCHAR2", "CHAR", "NCHAR", "NVARCHAR", "NVARCHAR2", "CHARACTER"}


def parse_data_type(rest):
    m = TYPE_PATTERN.match(rest.strip())
    if not m:
        return None, ""
    raw = re.sub(r"\s+", " ", m.group("type")).strip()
    remaining = rest.strip()[m.end():].strip()
    return raw, remaining


def max_length_from_type(raw):
    # Only set for text types
    if not raw:
        return ""
    base = re.match(r"(\w+)", raw).group(1).upper()
    if base in TEXT_TYPES:
        m = re.search(r"\(\s*(\d+)", raw)
        if m:
            return m.group(1)
    return ""


def parse_create_table(stmt):
    """Parse a CREATE TABLE statement. Return (table_name, [columns], inline_pk_cols, inline_fks)
    where columns is list of dicts: {name, type_raw, max_length, not_null, default}
    and inline_fks is list of dicts: {cols: [..], ref_table, ref_cols: [..]}.
    """
    m = re.search(r"create\s+(?:global\s+temporary\s+|table\s+)?table\s+(?:if\s+not\s+exists\s+)?"
                  r"(?:(?:\"?\w+\"?)\.)?\"?(?P<tname>\w+)\"?",
                  stmt, re.I)
    if not m:
        return None
    name = m.group("tname").upper()
    p_open = stmt.find("(", m.end())
    if p_open < 0:
        return None
    p_close = find_matching_paren(stmt, p_open)
    if p_close < 0:
        return None
    body = stmt[p_open + 1 : p_close]
    parts = split_top_commas(body)

    columns = []
    inline_pk_cols = []
    inline_fks = []
    seen_names = set()

    for raw_item in parts:
        item = raw_item.strip()
        if not item:
            continue
        # constraint?
        cm = re.match(r"^constraint\s+\w+\s+(.*)$", item, re.I | re.S)
        body_item = cm.group(1) if cm else item
        if re.match(r"^primary\s+key", body_item, re.I):
            inner_open = body_item.find("(")
            if inner_open >= 0:
                inner_close = find_matching_paren(body_item, inner_open)
                if inner_close > 0:
                    cols = [clean_id(c) for c in body_item[inner_open + 1 : inner_close].split(",")]
                    inline_pk_cols.extend(cols)
            continue
        if re.match(r"^foreign\s+key", body_item, re.I):
            io = body_item.find("(")
            ic = find_matching_paren(body_item, io) if io >= 0 else -1
            cols = []
            if 0 < io < ic:
                cols = [clean_id(c) for c in body_item[io + 1 : ic].split(",")]
            ref_m = re.search(r"references\s+(?:(?:\"?\w+\"?)\.)?\"?(\w+)\"?\s*(?:\(([^)]*)\))?",
                              body_item[ic + 1:] if ic > 0 else body_item, re.I)
            if ref_m:
                ref_table = ref_m.group(1).upper()
                ref_cols = []
                if ref_m.group(2):
                    ref_cols = [clean_id(c) for c in ref_m.group(2).split(",")]
                inline_fks.append({"cols": cols, "ref_table": ref_table, "ref_cols": ref_cols})
            continue
        if re.match(r"^(unique|check)\b", body_item, re.I):
            continue
        if CONSTRAINT_LEAD.match(item):
            continue

        # It's a column definition
        # Strip leading quoted name or bare identifier
        col_m = re.match(r'^"?(?P<cname>[A-Za-z_][\w$#]*)"?\s+(?P<rest>.*)$', item, re.S)
        if not col_m:
            continue
        cname = col_m.group("cname").upper()
        rest = col_m.group("rest").strip()
        raw_type, after = parse_data_type(rest)
        if raw_type is None:
            continue
        not_null = bool(re.search(r"\bnot\s+null\b", after, re.I))
        # inline PK on column?
        if re.search(r"\bprimary\s+key\b", after, re.I):
            inline_pk_cols.append(cname)
        # inline foreign key on column?
        ref_m = re.search(r"\breferences\s+(?:(?:\"?\w+\"?)\.)?\"?(\w+)\"?\s*(?:\(([^)]*)\))?", after, re.I)
        if ref_m:
            ref_cols = []
            if ref_m.group(2):
                ref_cols = [clean_id(c) for c in ref_m.group(2).split(",")]
            inline_fks.append({
                "cols": [cname],
                "ref_table": ref_m.group(1).upper(),
                "ref_cols": ref_cols,
            })
        if cname in seen_names:
            continue
        seen_names.add(cname)
        columns.append({
            "name": cname,
            "type_raw": raw_type.upper(),
            "max_length": max_length_from_type(raw_type),
            "not_null": not_null,
        })

    return {"name": name, "columns": columns, "pk_cols": inline_pk_cols, "fks": inline_fks}


# ------------------------- File scan -------------------------

# Patterns operating on whole files (after comment stripping)
CREATE_TABLE_RE = re.compile(r"create\s+(?:global\s+temporary\s+)?table\s+", re.I)
ALTER_TABLE_RE = re.compile(r"alter\s+table\s+", re.I)
COMMENT_TBL_RE = re.compile(
    r"comment\s+on\s+table\s+(?:(?:\"?\w+\"?)\.)?\"?(?P<tname>\w+)\"?\s+is\s+'(?P<txt>(?:''|[^'])*)'",
    re.I | re.S,
)
COMMENT_COL_RE = re.compile(
    r"comment\s+on\s+column\s+(?:(?:\"?\w+\"?)\.)?\"?(?P<tname>\w+)\"?\.\"?(?P<cname>\w+)\"?\s+is\s+'(?P<txt>(?:''|[^'])*)'",
    re.I | re.S,
)


def parse_file(path):
    raw = path.read_text(errors="replace")
    text = strip_comments(raw)

    tables = {}  # name -> table dict
    pk_extra = {}  # name -> list of pk col lists
    fk_extra = {}  # name -> list of fk dicts

    # CREATE TABLE statements
    for m in CREATE_TABLE_RE.finditer(text):
        start = m.start()
        p_open = text.find("(", m.end())
        if p_open < 0:
            continue
        p_close = find_matching_paren(text, p_open)
        if p_close < 0:
            continue
        # Find end of statement after p_close (look for ;)
        # We don't actually need ;; just pass through the substring including all the trailing storage clauses
        # but limit to next top-level ;
        sc = text.find(";", p_close)
        end = sc if sc > 0 else len(text)
        stmt = text[start:end]
        parsed = parse_create_table(stmt)
        if not parsed:
            continue
        if parsed["name"] in tables:
            # already saw it (e.g. duplicate) — skip
            continue
        tables[parsed["name"]] = parsed
        pk_extra.setdefault(parsed["name"], []).extend([parsed["pk_cols"]] if parsed["pk_cols"] else [])
        fk_extra.setdefault(parsed["name"], []).extend(parsed["fks"])

    # ALTER TABLE ... ADD CONSTRAINT ... PRIMARY KEY / FOREIGN KEY
    for m in ALTER_TABLE_RE.finditer(text):
        tail = text[m.end(): m.end() + 4000]
        tm = re.match(r"(?:(?:\"?\w+\"?)\.)?\"?(\w+)\"?", tail)
        if not tm:
            continue
        tname = tm.group(1).upper()
        # find next ;
        sc = text.find(";", m.end())
        stmt = text[m.end(): sc if sc > 0 else m.end() + 4000]
        # PK
        pkm = re.search(
            r"add\s+(?:constraint\s+\w+\s+)?primary\s+key\s*\(([^)]*)\)",
            stmt, re.I,
        )
        if pkm:
            cols = [clean_id(c) for c in pkm.group(1).split(",")]
            pk_extra.setdefault(tname, []).append(cols)
        # FK
        for fkm in re.finditer(
            r"add\s+(?:constraint\s+\w+\s+)?foreign\s+key\s*\(([^)]*)\)\s*"
            r"references\s+(?:(?:\"?\w+\"?)\.)?\"?(\w+)\"?\s*(?:\(([^)]*)\))?",
            stmt, re.I | re.S,
        ):
            cols = [clean_id(c) for c in fkm.group(1).split(",")]
            ref_table = fkm.group(2).upper()
            ref_cols = []
            if fkm.group(3):
                ref_cols = [clean_id(c) for c in fkm.group(3).split(",")]
            fk_extra.setdefault(tname, []).append(
                {"cols": cols, "ref_table": ref_table, "ref_cols": ref_cols}
            )

    # COMMENT ON TABLE
    table_comments = {}
    for m in COMMENT_TBL_RE.finditer(text):
        tname = m.group("tname").upper()
        txt = m.group("txt").replace("''", "'").strip()
        table_comments[tname] = txt

    # COMMENT ON COLUMN
    col_comments = {}  # (tname, cname) -> text
    for m in COMMENT_COL_RE.finditer(text):
        tname = m.group("tname").upper()
        cname = m.group("cname").upper()
        txt = m.group("txt").replace("''", "'").strip()
        col_comments[(tname, cname)] = txt

    return tables, pk_extra, fk_extra, table_comments, col_comments


# ------------------------- Description guessing -------------------------

WORD_GLOSSARY = {
    "TS": "time series",
    "TSV": "time series values",
    "ID": "identifier",
    "CODE": "internal numeric code",
    "DESC": "description",
    "DESCR": "description",
    "DESCRIPTION": "description",
    "NUM": "number",
    "QTY": "quantity",
    "AMT": "amount",
    "VAL": "value",
    "TF": "true/false flag",
    "FLAG": "flag",
    "DT": "date/time",
    "DTM": "date/time",
    "TZ": "time zone",
    "LOC": "location",
    "OFFC": "office",
    "OFFICE": "office",
    "GEO": "geographic",
    "GEOLOC": "geographic location",
    "PARAM": "parameter",
    "RATING": "rating",
    "TR": "transformation",
    "FK": "foreign key",
    "PK": "primary key",
    "LVL": "level",
    "REF": "reference",
    "SP": "spatial",
    "SHEF": "SHEF (Standard Hydrometeorological Exchange Format)",
    "FCST": "forecast",
    "INST": "instance",
    "SEC": "security",
    "MSG": "message",
    "ALARM": "alarm",
    "TSID": "time series identifier",
    "MV": "materialized view",
    "AV": "view",
    "AT": "application",
    "CWMS": "CWMS",
    "VLOC": "virtual location",
    "DSS": "HEC-DSS",
    "XCHG": "exchange",
    "CRREL": "CRREL",
    "PE": "Physical Element",
    "USGS": "USGS",
    "NWS": "NWS",
    "USACE": "USACE",
    "DAM": "dam",
    "CMA": "CMA",
    "A2W": "Access to Water",
    "NID": "National Inventory of Dams",
    "DQU": "data quality",
}


def humanize(name):
    """Convert snake_case to lowercase phrase using glossary."""
    parts = name.split("_")
    words = []
    for p in parts:
        if not p:
            continue
        up = p.upper()
        words.append(WORD_GLOSSARY.get(up, p.lower()))
    return " ".join(words)


def guess_table_desc(tname):
    n = tname.upper()
    prefix = ""
    rest = n
    if n.startswith("AT_"):
        prefix = "Application/transactional table for "
        rest = n[3:]
    elif n.startswith("CWMS_"):
        prefix = "CWMS reference table for "
        rest = n[5:]
    elif n.startswith("MV_"):
        prefix = "Materialized view storage for "
        rest = n[3:]
    elif n.startswith("AV_"):
        prefix = "View-related table for "
        rest = n[3:]
    return f"{prefix}{humanize(rest)}.".strip()


def guess_col_desc(tname, col, fk_target=None):
    n = col.upper()
    base_phrase = humanize(n)
    if n.endswith("_CODE"):
        guess = f"Internal numeric {humanize(n[:-5])} code (surrogate key)."
    elif n.endswith("_ID"):
        guess = f"{humanize(n[:-3]).capitalize()} identifier."
    elif n.endswith("_DATE") or n in ("CREATED", "UPDATED", "DATE_REFRESHED", "LAST_UPDATE"):
        guess = f"Date/time of {humanize(n).replace('date', '').strip()}.".replace("  ", " ")
    elif n.endswith("_FLAG") or n.endswith("_TF") or n == "FLAG":
        guess = f"Flag for {humanize(n[:-5] if n.endswith('_FLAG') else n[:-3] if n.endswith('_TF') else n)} (T/F)."
    elif n.endswith("_NAME"):
        guess = f"Name of {humanize(n[:-5])}."
    elif n.endswith("_DESC") or n.endswith("_DESCRIPTION"):
        guess = f"Description of {humanize(n.split('_DESC')[0])}."
    elif n.startswith("NUM_"):
        guess = f"Count of {humanize(n[4:])}."
    elif n in ("OFFICE_CODE",):
        guess = "Internal CWMS office code (surrogate key, FK to CWMS_OFFICE.OFFICE_CODE)."
    elif n in ("DB_OFFICE_ID", "OFFICE_ID"):
        guess = "Owning CWMS office identifier."
    elif n.startswith("TS_CODE"):
        guess = f"Time series code reference for {humanize(n[7:]) or 'a time series'}."
    elif n.startswith("RATING_CODE"):
        guess = f"Rating specification code for {humanize(n[11:]) or 'a rating'}."
    else:
        guess = f"{base_phrase.capitalize()}."
    if fk_target:
        guess = guess.rstrip(".") + f" (Foreign key to {fk_target})."
    return guess


# ------------------------- Main -------------------------

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--src", type=Path, default=DEFAULT_SRC,
                        help=f"schema SQL source root (default: {DEFAULT_SRC})")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT,
                        help=f"directory to write CSVs into (default: {DEFAULT_OUT})")
    parser.add_argument("--schema", default=DEFAULT_SCHEMA,
                        help=f"schema name in the CSVs (default: {DEFAULT_SCHEMA})")
    args = parser.parse_args(argv)

    src_root = args.src
    out_dir = args.out
    schema = args.schema
    build_files = build_file_list(src_root)

    all_tables = {}  # name -> table dict
    all_pks = {}     # name -> set(cols)
    all_fks = {}     # name -> list of fk dicts (cols [str], ref_table)
    all_tbl_comments = {}  # name -> text
    all_col_comments = {}  # (name, col) -> text
    source_file = {}  # name -> file rel

    for rel in build_files:
        path = src_root / rel
        if not path.exists():
            print(f"WARN missing: {rel}", file=sys.stderr)
            continue
        tables, pk_extra, fk_extra, tbl_comments, col_comments = parse_file(path)
        for tname, t in tables.items():
            if tname not in all_tables:
                all_tables[tname] = t
                source_file[tname] = rel
        for tname, pks in pk_extra.items():
            for cols in pks:
                if not cols:
                    continue
                all_pks.setdefault(tname, set()).update(cols)
        for tname, fks in fk_extra.items():
            for fk in fks:
                if not fk["cols"]:
                    continue
                all_fks.setdefault(tname, []).append(fk)
        for tname, txt in tbl_comments.items():
            all_tbl_comments.setdefault(tname, txt)
        for (tname, cname), txt in col_comments.items():
            all_col_comments.setdefault((tname, cname), txt)

    # Build FK lookup: (table, col) -> "REF_TABLE.REF_COL"
    fk_lookup = {}
    for tname, fks in all_fks.items():
        for fk in fks:
            ref_table = fk["ref_table"]
            ref_cols = fk.get("ref_cols") or []
            for i, c in enumerate(fk["cols"]):
                rc = ref_cols[i] if i < len(ref_cols) else (ref_cols[0] if ref_cols else "")
                ref = f"{ref_table}.{rc}" if rc else ref_table
                fk_lookup.setdefault((tname, c), ref)

    out_dir.mkdir(parents=True, exist_ok=True)

    # Write tables CSV
    tables_csv = out_dir / "cwms_20_tables.csv"
    with tables_csv.open("w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["Schema Name", "Table Name", "Description"])
        for tname in sorted(all_tables):
            desc = all_tbl_comments.get(tname)
            if not desc:
                desc = guess_table_desc(tname)
            w.writerow([schema, tname, desc])

    # Write columns CSV
    cols_csv = out_dir / "cwms_20_columns.csv"
    with cols_csv.open("w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow([
            "Schema Name",
            "Table Name",
            "Column Name",
            "Description",
            "Primary Key",
            "Data Type - Raw",
            "Maximum Length",
        ])
        for tname in sorted(all_tables):
            t = all_tables[tname]
            pk_set = all_pks.get(tname, set())
            for col in t["columns"]:
                fk_target = fk_lookup.get((tname, col["name"]))
                desc = all_col_comments.get((tname, col["name"]))
                if not desc:
                    desc = guess_col_desc(tname, col["name"], fk_target=fk_target)
                else:
                    if fk_target and "foreign key" not in desc.lower():
                        desc = desc.rstrip(". ") + f". (Foreign key to {fk_target}.)"
                is_pk = "True" if col["name"] in pk_set else "False"
                w.writerow([
                    schema,
                    tname,
                    col["name"],
                    desc,
                    is_pk,
                    col["type_raw"],
                    col["max_length"],
                ])

    print(f"Wrote {tables_csv} ({len(all_tables)} tables)")
    total_cols = sum(len(t['columns']) for t in all_tables.values())
    print(f"Wrote {cols_csv} ({total_cols} columns)")


if __name__ == "__main__":
    main()
