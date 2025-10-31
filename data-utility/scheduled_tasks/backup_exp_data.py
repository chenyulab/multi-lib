#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import re
import sys
import shutil
import zipfile
import logging
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Iterable, List

# --------------------------
# Logging
# --------------------------

def setup_logger(log_path: Path | None, verbose: bool) -> logging.Logger:
    logger = logging.getLogger("backup")
    logger.setLevel(logging.DEBUG)
    logger.handlers.clear()

    fmt = logging.Formatter("%(message)s")
    if log_path is None:
        sh = logging.StreamHandler(sys.stdout)
        sh.setLevel(logging.DEBUG if verbose else logging.INFO)
        sh.setFormatter(fmt)
        logger.addHandler(sh)
    else:
        fh = logging.FileHandler(log_path, encoding="utf-8")
        fh.setLevel(logging.DEBUG)
        fh.setFormatter(fmt)
        logger.addHandler(fh)
        if verbose:
            sh = logging.StreamHandler(sys.stdout)
            sh.setLevel(logging.DEBUG)
            sh.setFormatter(fmt)
            logger.addHandler(sh)
    return logger

# --------------------------
# Core copy helpers
# --------------------------

@dataclass
class BackupOptions:
    extensions: Iterable[str] = field(default_factory=lambda: ['.txt', '.png', '.jpg', '.csv', '.xlsx'])
    overwrite: bool = True
    dry_run: bool = False
    verbose: bool = True
    target_subfolders: Iterable[str] = field(default_factory=lambda: ['stimuli_images', 'survey_data', 'MCDI'])

def _norm_exts(exts: Iterable[str]) -> List[str]:
    return [e.lower() if e.startswith('.') else f".{e.lower()}" for e in exts]

def _copy_file(src: Path, dst: Path, opts: BackupOptions, log: logging.Logger):
    if dst.exists() and not opts.overwrite:
        log.info(f"SKIP (exists): {dst}")
        return
    if opts.dry_run:
        log.info(f"COPY: {src}  -->  {dst}")
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    try:
        shutil.copy2(src, dst)
        log.info(f"COPIED: {src}  -->  {dst}")
    except Exception as e:
        log.info(f"ERROR copying: {src}  -->  {dst}")
        log.info(f"  Reason: {e}")

def _copy_matches_in_folder(src_folder: Path, dst_folder: Path, exts: List[str], opts: BackupOptions, log: logging.Logger):
    if not src_folder.is_dir():
        return
    for p in src_folder.iterdir():
        if p.is_file() and p.suffix.lower() in exts:
            _copy_file(p, dst_folder / p.name, opts, log)
    for p in src_folder.iterdir():  # safety, case-insensitive
        if p.is_file() and any(p.name.lower().endswith(e) for e in exts):
            _copy_file(p, dst_folder / p.name, opts, log)

def _copy_matches_recursive(src_folder: Path, dst_folder: Path, exts: List[str], opts: BackupOptions, log: logging.Logger):
    if not src_folder.is_dir():
        return
    for root, _, files in os.walk(src_folder):
        rp = Path(root)
        for fname in files:
            if fname.lower().endswith(tuple(exts)):
                src = rp / fname
                rel = src.relative_to(src_folder)
                dst = dst_folder / rel
                _copy_file(src, dst, opts, log)

# --------------------------
# Part 1: backup_multiwork_files (uses provided backup_base_dir)
# --------------------------

def backup_multiwork_files(source_root: Path | str, dest_root: Path | str, opts: BackupOptions = BackupOptions()):
    source_root = Path(source_root)
    dest_root = Path(dest_root)

    if not source_root.is_dir():
        raise FileNotFoundError(f"Source folder does not exist: {source_root}")
    if not opts.dry_run:
        dest_root.mkdir(parents=True, exist_ok=True)

    # log file lives inside the SAME dest_root
    tstamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    log_path = None if opts.dry_run else dest_root / f"backup_log_{tstamp}.txt"
    log = setup_logger(log_path, opts.verbose)

    exts = _norm_exts(opts.extensions)
    exp_pat = re.compile(r"^experiment_\d{2,3}$", re.IGNORECASE)

    log.info(f"=== BACKUP START {datetime.now():%Y-%m-%d %H:%M:%S} ===")
    log.info(f"Source: {source_root}")
    log.info(f"Destination: {dest_root}")
    log.info(f"Extensions: {', '.join(exts)}")
    log.info(f"Overwrite: {int(opts.overwrite)}  DryRun: {int(opts.dry_run)}  Verbose: {int(opts.verbose)}")
    log.info("---")

    # 1) Top-level files
    log.info("Step 1: Top-level files in source_root")
    _copy_matches_in_folder(source_root, dest_root, exts, opts, log)

    # 2) Experiment folders
    log.info("Step 2: Experiment folders")
    for child in source_root.iterdir():
        if child.is_dir() and exp_pat.match(child.name):
            exp_src = child
            exp_dst = dest_root / child.name
            log.info(f"> Found experiment: {child.name}")
            if not opts.dry_run:
                exp_dst.mkdir(parents=True, exist_ok=True)

            # 2a) Files in experiment root
            _copy_matches_in_folder(exp_src, exp_dst, exts, opts, log)

            # 2b) Selected subfolders (recursive)
            for sub_name in opts.target_subfolders:
                sub_src = exp_src / sub_name
                if sub_src.is_dir():
                    log.info(f"  - Including subfolder (recursive): {child.name}/{sub_name}")
                    sub_dst = exp_dst / sub_name
                    if not opts.dry_run:
                        sub_dst.mkdir(parents=True, exist_ok=True)
                    _copy_matches_recursive(sub_src, sub_dst, exts, opts, log)
                else:
                    log.info(f"  - Missing subfolder (skipped): {child.name}/{sub_name}")

    log.info(f"=== BACKUP COMPLETE {datetime.now():%Y-%m-%d %H:%M:%S} ===")

# --------------------------
# Part 2: Subject-wise backup (uses SAME backup_base_dir)
# --------------------------

def backup_subjects_autodiscover(
    multiwork_root: Path,
    backup_base_dir: Path,                  # <-- now we accept the SAME folder
    subject_folders_to_copy: Iterable[str],
    include_extra_p_rules: bool = True,
):
    """
    Discover experiments/subjects and copy into the provided backup_base_dir (no new timestamp).
    """
    backup_base_dir.mkdir(parents=True, exist_ok=True)
    print(f"[INFO] Backup staging: {backup_base_dir}")

    exp_pat = re.compile(r"^experiment_\d{2,3}$", re.IGNORECASE)
    subj_pat = re.compile(r"^__\d{8}_\d+$")  # e.g., __20160225_17406

    experiments = [p for p in multiwork_root.iterdir() if p.is_dir() and exp_pat.match(p.name)]

    for exp_dir in experiments:
        included = exp_dir / "included"
        if not included.is_dir():
            print(f"[WARN] No 'included' folder in {exp_dir}")
            continue

        subjects = [p for p in included.iterdir() if p.is_dir() and subj_pat.match(p.name)]
        if not subjects:
            print(f"[WARN] No subject folders found in: {included}")
            continue

        out_exp_dir = backup_base_dir / exp_dir.name
        out_exp_dir.mkdir(parents=True, exist_ok=True)

        for subj_dir in subjects:
            subj_name = subj_dir.name  # e.g., __20160225_17406
            out_subj_dir = out_exp_dir / subj_name
            out_subj_dir.mkdir(parents=True, exist_ok=True)

            # Trial info files
            trial_info_mat = subj_dir / f"{subj_name}_info.mat"
            trial_info_txt = subj_dir / f"{subj_name}_info.txt"

            if trial_info_mat.exists():
                shutil.copy2(trial_info_mat, out_subj_dir)
            else:
                print(f"[WARN] MAT file not found: {trial_info_mat}")

            if trial_info_txt.exists():
                shutil.copy2(trial_info_txt, out_subj_dir)
            else:
                print(f"[WARN] TXT file not found: {trial_info_txt}")

            # Copy configured subfolders
            for folder_name in subject_folders_to_copy:
                src_folder = subj_dir / folder_name
                dst_folder = out_subj_dir / folder_name

                if folder_name == "extra_p" and include_extra_p_rules and src_folder.is_dir():
                    dst_folder.mkdir(parents=True, exist_ok=True)
                    for p in src_folder.glob("*boxes.mat"):
                        shutil.copy2(p, dst_folder / p.name)
                    for p in src_folder.glob("*boxes_face.mat"):
                        shutil.copy2(p, dst_folder / p.name)

                elif folder_name == "supporting_files" and src_folder.is_dir():
                    dst_folder.mkdir(parents=True, exist_ok=True)
                    for p in src_folder.iterdir():
                        if p.is_file():
                            shutil.copy2(p, dst_folder / p.name)

                elif src_folder.is_dir():
                    if dst_folder.exists():
                        shutil.rmtree(dst_folder)
                    shutil.copytree(src_folder, dst_folder)
                else:
                    print(f"[WARN] Missing folder for subject {subj_name}: {src_folder}")

# --------------------------
# Zipping + cleanup (uses SAME backup_base_dir)
# --------------------------

def zip_move_cleanup(backup_base_dir: Path, zip_destination_dir: Path):
    zip_destination_dir.mkdir(parents=True, exist_ok=True)
    zip_file_path = backup_base_dir.with_suffix(".zip")
    print(f"[INFO] Creating zip: {zip_file_path.name}")
    try:
        with zipfile.ZipFile(zip_file_path, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
            parent = backup_base_dir.parent
            for root, _, files in os.walk(backup_base_dir):
                for fname in files:
                    fpath = Path(root) / fname
                    arcname = fpath.relative_to(parent)  # relative to parent dir
                    zf.write(fpath, arcname)

        final_zip = zip_destination_dir / zip_file_path.name
        shutil.move(str(zip_file_path), final_zip)
        print(f"[INFO] Zip moved to: {final_zip}")

        shutil.rmtree(backup_base_dir)
        print(f"[INFO] Deleted staging folder: {backup_base_dir}")
    except Exception as e:
        print(f"[ERROR] During ZIP or cleanup: {e}")

# --------------------------
# CONFIG + MAIN
# --------------------------

def main():
    # Paths
    multiwork_path = Path(r"M:\ ").resolve()
    multiwork_path = Path(str(multiwork_path).strip())
    y_drive = Path(r"Y:\ ").resolve()
    y_drive = Path(str(y_drive).strip())

    # Single timestamp + SINGLE backup_base_dir
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_base_dir = y_drive / f"backup_{timestamp}"

    # Where the final zip should go
    zip_destination_dir = y_drive / r"multiwork_active_exp_backup\data_backup"

    # Subject subfolders to copy
    subject_folders = ['derived', 'reliability', 'speech_transcription_p', 'supporting_files']
    # If you also need 'extra_p', uncomment:
    # subject_folders = ['derived', 'reliability', 'speech_transcription_p', 'supporting_files', 'extra_p']

    # STEP 1: sweep multiwork files into SAME backup_base_dir
    print("[INFO] Running backup_multiwork_files(...)")
    backup_multiwork_files(
        source_root=multiwork_path,
        dest_root=backup_base_dir,
        opts=BackupOptions(
            extensions=['.txt', '.png', '.jpg', '.csv', '.xlsx'],
            overwrite=True,
            dry_run=False,
            verbose=True,
            target_subfolders=['stimuli_images', 'survey_data', 'MCDI']
        )
    )

    # STEP 2: subjects into SAME backup_base_dir
    print("[INFO] Running backup_subjects_autodiscover(...)")
    backup_subjects_autodiscover(
        multiwork_root=multiwork_path,
        backup_base_dir=backup_base_dir,             # <-- SAME FOLDER
        subject_folders_to_copy=subject_folders,
        include_extra_p_rules=True,
    )

    # STEP 3: zip/move/cleanup using SAME backup_base_dir
    zip_move_cleanup(backup_base_dir=backup_base_dir, zip_destination_dir=zip_destination_dir)

if __name__ == "__main__":
    main()
