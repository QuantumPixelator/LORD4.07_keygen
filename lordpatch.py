"""
lordpatch.py — Patch lordcfg.exe to accept any registration numbers.

Patches a single byte in the registration check so that entering
any 5 numbers (including all zeros) passes verification.

Usage:
    python lordpatch.py [path\\to\\LORDCFG.EXE]

If no path is given, a file-open dialog is shown to select LORDCFG.EXE.
A backup is saved as LORDCFG.BAK before patching.
"""

import sys
import shutil
from pathlib import Path


def ask_for_file() -> Path:
    """Open a native file-chooser dialog and return the selected path."""
    try:
        import tkinter as tk
        from tkinter import filedialog

        root = tk.Tk()
        root.withdraw()
        root.attributes("-topmost", True)
        chosen = filedialog.askopenfilename(
            title="Select LORDCFG.EXE",
            filetypes=[("EXE files", "*.exe"), ("All files", "*.*")],
        )
        root.destroy()
        if not chosen:
            print("No file selected. Aborting.")
            sys.exit(0)
        return Path(chosen)
    except Exception as e:
        print(f"Could not open file dialog: {e}")
        print("Usage: python lordpatch.py <path to LORDCFG.EXE>")
        sys.exit(1)


# Single-byte patch in the registration check (reversed from lordcfg.exe):
#
#   virtual 0x1BB6:  C6 06 18 02 01   mov [0x218], 1   ; success → registered
#   virtual 0x1BBB:  EB 05            jmp past fail
#   virtual 0x1BBD:  C6 06 18 02 00   mov [0x218], 0   ; fail → NOT registered
#                                                ^^
#                                          PATCH: 00 → 01
#
# After patch both paths write 1 (registered), so any numbers are accepted.

CODE_OFFSET = 0x58E0
PATCH_VIRT = 0x1BBD
PATCH_FILE = CODE_OFFSET + PATCH_VIRT  # 0x749D
FIND_BYTES = bytes([0xC6, 0x06, 0x18, 0x02, 0x00])
REPLACE_BYTES = bytes([0xC6, 0x06, 0x18, 0x02, 0x01])


def patch(exe_path: Path) -> None:
    if not exe_path.exists():
        print(f"Error: file not found: {exe_path}")
        sys.exit(1)

    data = bytearray(exe_path.read_bytes())

    actual = bytes(data[PATCH_FILE : PATCH_FILE + len(FIND_BYTES)])

    if actual == REPLACE_BYTES:
        print(f"Already patched: {exe_path}")
        return

    if actual != FIND_BYTES:
        print(f"Error: unexpected bytes at offset 0x{PATCH_FILE:X}:")
        print(f"  Expected: {FIND_BYTES.hex(' ')}")
        print(f"  Found:    {actual.hex(' ')}")
        print("Wrong version of LORDCFG.EXE, or file is already modified.")
        sys.exit(1)

    # Backup
    backup = exe_path.with_suffix(".BAK")
    shutil.copy2(exe_path, backup)
    print(f"Backup saved: {backup}")

    # Apply patch
    data[PATCH_FILE : PATCH_FILE + len(REPLACE_BYTES)] = REPLACE_BYTES
    exe_path.write_bytes(data)

    print(f"Patched:  {exe_path}")
    print(f"  Offset: 0x{PATCH_FILE:X}  (virtual CS:0x{PATCH_VIRT:X})")
    print(f"  Before: {FIND_BYTES.hex(' ')}")
    print(f"  After:  {REPLACE_BYTES.hex(' ')}")
    print()
    print("lordcfg.exe will now accept any registration numbers.")
    print("Just enter 1 2 3 4 5 (or any numbers) when prompted.")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        path = Path(sys.argv[1])
    else:
        path = ask_for_file()
    patch(path)
