#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
INCREMENTAL VIDEO BACKUP
- Scans all experiment_* folders in MULTIWORK_ROOT.
- For each experiment, finds subjects inside 'included' matching '__YYYYMMDD_XXXXX'.
- Under each subject, finds camera folders matching 'camNN_video_r'.
- Recursively copies only NEW or CHANGED video files (by size/mtime) to a time-stamped batch.
- Updates persistent CSV manifest so future runs are incremental.

Tested on Windows-style paths. Requires Python 3.9+.
"""

import os
import re
import csv
import sys
import shutil
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Iterable, Dict, Tuple, List

# =============== CONFIG ===============
MULTIWORK_ROOT = Path(r"M:\ ").resolve()     # root containing experiment_* folders
MULTIWORK_ROOT = Path(str(MULTIWORK_ROOT).strip())

DEST_ROOT      = Path(r"Y:\multiwork_active_exp_backup\video_backup_incremental").resolve()
VIDEO_EXTS     = ['.mp4', '.avi', '.mov', '.mkv', '.m4v']  # case-insensitive
CAM_DIR_REGEX  = re.compile(r"^cam\d{2}_video_r$", re.IGNORECASE)
EXP_REGEX      = re.compile(r"^experiment_\d{2,3}$", re.IGNORECASE)
SUBJ_REGEX     = re.compile(r"^__\d{8}_\d+$")              # e.g., __20160225_17406

DRY_RUN        = False  # True = simulate, print actions, no copying
# ======================================


@dataclass
class Counters:
    copied_ok: int = 0
    failed: int = 0


@dataclass
class PlanRow:
    rel_path: str
    size: int
    mtime: float
    src: Path
    dst: Path


@dataclass
class Manifest:
    rows: Dict[str, Tuple[int, float]] = field(default_factory=dict)  # rel_path -> (size, mtime)

    @staticmethod
    def load(csv_path: Path) -> "Manifest":
        m = Manifest()
        if csv_path.exists():
            with csv_path.open('r', newline='', encoding='utf-8') as f:
                reader = csv.DictReader(f)
                # expects: rel_path,size,mtime
                for row in reader:
                    rel = row.get('rel_path', '')
                    if not rel:
                        continue
                    try:
                        size = int(float(row.get('size', '0')))
                        mtime = float(row.get('mtime', '0'))
                    except Exception:
                        continue
                    m.rows[rel] = (size, mtime)
        return m

    def save(self, csv_path: Path):
        csv_path.parent.mkdir(parents=True, exist_ok=True)
        with csv_path.open('w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=['rel_path', 'size', 'mtime'])
            writer.writeheader()
            for rel_path, (size, mtime) in self.rows.items():
                writer.writerow({'rel_path': rel_path, 'size': size, 'mtime': mtime})

    def needs_copy(self, rel_path: str, size: int, mtime: float) -> bool:
        """Return True if file is NEW or CHANGED vs manifest."""
        if rel_path not in self.rows:
            return True
        old_size, old_mtime = self.rows[rel_path]
        return (old_size != size) or (old_mtime < mtime)

    def upsert(self, rel_path: str, size: int, mtime: float):
        self.rows[rel_path] = (size, mtime)


def _norm_rel_path(*parts: Path | str) -> str:
    """Make a stable, manifest-friendly relative path using forward slashes."""
    p = Path(*[str(x) for x in parts])
    return p.as_posix()


def list_video_files(cam_root: Path, video_exts: Iterable[str]) -> List[Path]:
    """Recursively list files under cam_root with any of the extensions (case-insensitive)."""
    out: List[Path] = []
    exts = tuple(e.lower() if e.startswith('.') else f".{e.lower()}" for e in video_exts)
    for root, _, files in os.walk(cam_root):
        rpath = Path(root)
        for fname in files:
            if fname.lower().endswith(exts):
                out.append(rpath / fname)
    return out


def discover_subjects(exp_dir: Path) -> List[Path]:
    """Find subject dirs (pattern __YYYYMMDD_XXXXX) under exp_dir/included. 
       Also supports subjects directly under exp_dir if needed."""
    candidates: List[Path] = []
    included = exp_dir / "included"
    if included.is_dir():
        for p in included.iterdir():
            if p.is_dir() and SUBJ_REGEX.match(p.name):
                candidates.append(p)
    else:
        # fallback: look one level under exp_dir (rare, but safe)
        for p in exp_dir.iterdir():
            if p.is_dir() and SUBJ_REGEX.match(p.name):
                candidates.append(p)
    return candidates


def plan_copies(multiwork_root: Path, batch_dir: Path, manifest: Manifest) -> List[PlanRow]:
    """Scan all experiments/subjects/cams and produce copy plan for new/changed files."""
    plan: List[PlanRow] = []

    experiments = [p for p in multiwork_root.iterdir() if p.is_dir() and EXP_REGEX.match(p.name)]
    print(f"[{datetime.now():%Y-%m-%d %H:%M:%S}] Scanning experiments... found {len(experiments)}")

    for exp_dir in experiments:
        subjects = discover_subjects(exp_dir)
        if not subjects:
            print(f"[WARN] No subjects found in: {exp_dir}")
            continue

        for subj_dir in subjects:
            # camera dirs directly under subject
            try:
                for cam_dir in subj_dir.iterdir():
                    if cam_dir.is_dir() and CAM_DIR_REGEX.match(cam_dir.name):
                        files = list_video_files(cam_dir, VIDEO_EXTS)
                        for src in files:
                            # rel path below cam root
                            rel_under_cam = src.relative_to(cam_dir)
                            rel_path = _norm_rel_path(exp_dir.name, subj_dir.name, cam_dir.name, rel_under_cam)

                            try:
                                stat = src.stat()
                                size = int(stat.st_size)
                                mtime = float(stat.st_mtime)
                            except FileNotFoundError:
                                continue  # file vanished mid-scan

                            if manifest.needs_copy(rel_path, size, mtime):
                                dst = batch_dir / Path(rel_path)  # preserve structure
                                plan.append(PlanRow(rel_path=rel_path, size=size, mtime=mtime, src=src, dst=dst))
            except PermissionError as e:
                print(f"[WARN] Permission error in {subj_dir}: {e}")
                continue

    # Deduplicate by rel_path (keep first occurrence)
    seen = set()
    deduped: List[PlanRow] = []
    for row in plan:
        if row.rel_path not in seen:
            seen.add(row.rel_path)
            deduped.append(row)
    return deduped


def execute_copies(plan: List[PlanRow], manifest: Manifest, dry_run: bool) -> Counters:
    cnt = Counters()
    for row in plan:
        row.dst.parent.mkdir(parents=True, exist_ok=True)
        try:
            if not dry_run:
                shutil.copy2(row.src, row.dst)  # preserves timestamps
            cnt.copied_ok += 1
            manifest.upsert(row.rel_path, row.size, row.mtime)
        except Exception as e:
            cnt.failed += 1
            print(f"[WARN] Copy failed: {row.src} -> {row.dst} ({e})")
    return cnt


def main():
    if not MULTIWORK_ROOT.is_dir():
        print(f"[ERROR] Multiwork root not found: {MULTIWORK_ROOT}")
        sys.exit(1)

    DEST_ROOT.mkdir(parents=True, exist_ok=True)
    manifest_path = DEST_ROOT / "manifest.csv"

    # single timestamped batch folder per run
    batch_dir = DEST_ROOT / datetime.now().strftime("%Y%m%d_%H%M%S")
    batch_dir.mkdir(parents=True, exist_ok=True)

    # load manifest
    manifest = Manifest.load(manifest_path)

    # plan
    plan = plan_copies(MULTIWORK_ROOT, batch_dir, manifest)
    print(f"[{datetime.now():%Y-%m-%d %H:%M:%S}] Files to copy: {len(plan)}")

    # execute
    counters = execute_copies(plan, manifest, DRY_RUN)

    # save manifest
    if not DRY_RUN:
        manifest.save(manifest_path)

    print(f"[{datetime.now():%Y-%m-%d %H:%M:%S}] Incremental backup done. "
          f"Copied OK: {counters.copied_ok}, Failed: {counters.failed}, "
          f"Batch folder: {batch_dir}")

if __name__ == "__main__":
    main()
