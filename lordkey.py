"""
lordkey.py — Registration key generator for Legend of the Red Dragon (LORD) v4.07
Reversed from lord/lordcfg.exe (function at virtual CS:0x03F7)

Algorithm:
  Takes the Sysop Name and BBS Name (both uppercased), computes 5 integer
  registration keys that must be entered into lordcfg.exe during registration.

Usage:
  python lordkey.py
  python lordkey.py "Sysop Name" "BBS Name"

How it works (from binary analysis of lordcfg.exe):
  lordcfg.exe computes keys from the names, stores them in LORD.DAT.
  During verification it re-computes from the entered names and compares
  against the stored values.  The comparison path proves:

    entered_key == raw_accumulated_sum_before_internal_byteswap

  So lordkey.py outputs exactly those raw sums.
"""

import sys
from counter import increment_counter

# ANSI color constants for retro BBS feel (works on Linux terminals)
RESET = "\033[0m"
BOLD = "\033[1m"
RED = "\033[31m"
YELLOW = "\033[33m"
CYAN = "\033[36m"

LORD_BANNER = r"""
    _      _____  _____  _____
 | |    |  _  ||  _  ||  _  |
 | |    | | | || | | || | | |
 | |__  | |_| || |_| || |_| |
 |____| |_____||_____||_____|

    LEGEND OF THE RED DRAGON — Key Generator
"""


def compute_lord_keys(sysop_name: str, bbs_name: str) -> tuple[int, int, int, int, int]:
    """
    Compute the 5 LORD registration keys from sysop name and BBS name.

    Reversed from lordcfg.exe function at virtual 0x03F7 (Turbo Pascal 7, 16-bit DOS).

    Parameters
    ----------
    sysop_name : str  — Sysop / operator name (case-insensitive)
    bbs_name   : str  — BBS name (case-insensitive)

    Returns
    -------
    (key1, key2, key3, key4, key5) — five integers, each in range 0–65535
    """
    # Both names are uppercased inside lordcfg.exe before keying
    sysop = sysop_name.upper()
    bbs = bbs_name.upper()

    sysop_b = [ord(c) for c in sysop]
    bbs_b = [ord(c) for c in bbs]

    # ---------------------------------------------------------------
    # KEY 1 — from sysop name, 16-bit
    #   For each char (1-indexed):
    #     odd  index → key1 += char          (char in low byte)
    #     even index → key1 += char * 256    (char in high byte)
    # ---------------------------------------------------------------
    acc1 = 0
    for i, ch in enumerate(sysop_b, start=1):
        if i & 1:  # odd index
            acc1 = (acc1 + ch) & 0xFFFF
        else:  # even index
            acc1 = (acc1 + (ch << 8)) & 0xFFFF
    key1 = acc1

    # ---------------------------------------------------------------
    # KEY 2 — from BBS name, same algorithm, 32-bit accumulator
    # ---------------------------------------------------------------
    acc2 = 0
    for i, ch in enumerate(bbs_b, start=1):
        if i & 1:
            acc2 = (acc2 + ch) & 0xFFFFFFFF
        else:
            acc2 = (acc2 + (ch << 8)) & 0xFFFFFFFF
    key2 = acc2 & 0xFFFF  # use only low word

    # ---------------------------------------------------------------
    # KEY 3 — interleaved sysop + bbs, 32-bit
    #   If the names differ in length, the shorter one is padded with
    #   bytes 0x00, 0x01, 0x02 … until lengths match.
    #   Then for i = 1 … max_len:
    #     odd  index → char from (padded) sysop
    #     even index → char from (padded) bbs
    # ---------------------------------------------------------------
    ps = list(sysop_b)
    pb = list(bbs_b)
    if len(ps) > len(pb):
        ctr = 0
        while len(pb) < len(ps):
            pb.append(ctr & 0xFF)
            ctr += 1
    elif len(pb) > len(ps):
        ctr = 0
        while len(ps) < len(pb):
            ps.append(ctr & 0xFF)
            ctr += 1

    acc3 = 0
    for i in range(1, len(ps) + 1):
        ch = ps[i - 1] if (i & 1) else pb[i - 1]
        acc3 = (acc3 + ch) & 0xFFFFFFFF
    key3 = acc3  # 32-bit, no byte-swap

    # ---------------------------------------------------------------
    # KEY 4 — sysop chars divided by count of valid chars
    #   valid chars = space or A–Z (capped at 4)
    #   key4 = sum(char >> 1 for char in sysop) // valid_count
    # ---------------------------------------------------------------
    valid_count = sum(1 for c in sysop if c == " " or "A" <= c <= "Z")
    valid_count = min(valid_count, 4)

    acc4 = 0
    for ch in sysop_b:
        acc4 = (acc4 + (ch >> 1)) & 0xFFFFFFFF
    if valid_count > 0:
        acc4 = acc4 // valid_count
    key4 = acc4 & 0xFFFF

    # ---------------------------------------------------------------
    # KEY 5 — BBS chars, doubled if below halfway threshold
    #   Doubling condition: 0x7FFFFFFE − acc5 > acc5
    #                  i.e.  acc5 < 0x3FFFFFFF
    # ---------------------------------------------------------------
    acc5 = 0
    for ch in bbs_b:
        acc5 = (acc5 + (ch >> 1)) & 0xFFFFFFFF
    if (0x7FFFFFFE - acc5) > acc5:  # acc5 < 0x3FFFFFFF
        acc5 = (acc5 * 2) & 0xFFFFFFFF
    key5 = acc5 & 0xFFFF

    return key1, key2, key3, key4, key5


def main() -> None:
    if len(sys.argv) == 3:
        sysop_name = sys.argv[1]
        bbs_name = sys.argv[2]
    else:
        # Printed header with ANSI styling for a retro BBS look
        print(BOLD + RED + LORD_BANNER + RESET)
        print(YELLOW + "Reverse-engineered by Quantum Pixelator" + RESET)
        sysop_name = input("Enter Sysop Name : ").strip()
        bbs_name = input("Enter BBS Name   : ").strip()

    if not sysop_name or not bbs_name:
        print("Error: both sysop name and BBS name are required.")
        sys.exit(1)

    k1, k2, k3, k4, k5 = compute_lord_keys(sysop_name, bbs_name)

    # increment private usage counter (not shown to the user)
    try:
        increment_counter()
    except Exception:
        # don't fail the keygen if counting errors occur
        pass

    print()
    print(BOLD + CYAN + "=" * 60 + RESET)
    print(BOLD + YELLOW + f"  Sysop Name : {sysop_name.upper()}" + RESET)
    print(BOLD + YELLOW + f"  BBS Name   : {bbs_name.upper()}" + RESET)
    print(BOLD + CYAN + "=" * 60 + RESET)
    print(BOLD + RED + f"  Number 1 : {k1}" + RESET)
    print(BOLD + RED + f"  Number 2 : {k2}" + RESET)
    print(BOLD + RED + f"  Number 3 : {k3}" + RESET)
    print(BOLD + RED + f"  Number 4 : {k4}" + RESET)
    print(BOLD + RED + f"  Number 5 : {k5}" + RESET)
    print(BOLD + CYAN + "=" * 60 + RESET)
    print(BOLD + YELLOW + "  Enter these when lordcfg.exe asks for the 5 numbers." + RESET)
    print(BOLD + CYAN + "=" * 60 + RESET)


if __name__ == "__main__":
    main()
