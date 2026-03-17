# LORD v4.07 — Registration Keygen & Patcher

Registration key generator and binary patcher for **Legend of the Red Dragon (LORD) v4.07**,
a classic BBS door game by Seth Able Robinson / Metropolis Inc., circa 2006.

Both a **Windows GUI** (`.exe`) and a **Python CLI** version are provided for each tool.
---
---
## IF YOU JUST WANT YOUR KEYS:
- [Online Link](http://192.3.16.80:8000/ui)
- [Direct API](http://192.3.16.80:8000/api/keys?sysop=Anonymous&bbs=CoolBBS)
    - If you use direct API, change the "sysop=" to sysop name, and "bbs=" to your BBS name
---
---

## Tools

| File | Description |
|------|-------------|
| `lordkey.exe` | Win64 GUI  enter names, get 5 registration numbers |
| `lordkey.pas` | Free Pascal source for the GUI keygen |
| `lordkey.py` | Python CLI version of the keygen |
| `lordpatch.exe` | Win64 GUI  browse to `LORDCFG.EXE`, back it up, and patch it |
| `lordpatch.pas` | Free Pascal source for the GUI patcher |
| `lordpatch.py` | Python CLI version of the patcher |

---

## NOTICE: Use one or the other: lordkey.exe or lordpatch.exe, but not both.


## lordkey — Registration Keygen

Computes the five numbers that `lordcfg.exe` requires during registration.

### GUI usage (`lordkey.exe`)

1. Enter the **Sysop Name** exactly as you will type it in `lordcfg.exe`
2. Enter the **BBS Name** exactly as you will type it in `lordcfg.exe`
3. Click **Generate Keys**
4. Enter the five resulting numbers into `lordcfg.exe` when prompted

Names are case-insensitive — `lordcfg.exe` uppercases them before computing.

### CLI usage (`lordkey.py`)

```
python lordkey.py "Sysop Name" "BBS Name"
```

Or run `python lordkey.py` with no arguments for an interactive prompt.

---

## lordpatch — Binary Patcher

If you can't (or don't want to) generate exact keys, the patcher modifies `lordcfg.exe` so
that **any five numbers** pass registration, including all zeros.

A backup is saved as `LORDCFG.BAK` before any changes are made.

### GUI usage (`lordpatch.exe`)

1. Click **Browse** and select `LORDCFG.EXE`
2. Click **Backup & Patch LORDCFG.EXE**
3. The log confirms the backup path and the byte that was changed

### CLI usage (`lordpatch.py`)

```
python lordpatch.py "C:\LORD\LORDCFG.EXE"
```

Or run `python lordpatch.py` with no arguments — a file-open dialog appears.

---

## How the keygen algorithm works

Reversed from `lordcfg.exe`, function at virtual `CS:0x03F7`
(Turbo Pascal 7.0, 16-bit DOS executable).

Both names are uppercased before any arithmetic. Five independent 16-bit keys are produced:

### Key 1 — Sysop name, alternate byte placement

For each character (1-indexed):

- **Odd** index  add `char` to low byte of accumulator
- **Even** index  add `char x 256` (shift into high byte)

### Key 2 — BBS name, same alternating scheme (32-bit accumulator, low word used)

### Key 3 — Interleaved sysop + BBS

Both names are zero-padded to equal length, then for position `i`:
odd positions take the sysop byte, even positions take the BBS byte.

### Key 4 — Sysop name divided by valid-char count

`valid_count` = number of spaces or AZ characters in sysop name, capped at 4.  
`key4 = sum(char >> 1 for char in sysop) // valid_count`

### Key 5 — BBS name, halved and conditionally doubled

`acc = sum(char >> 1 for char in bbs)`  
If `acc < 0x3FFFFFFF` then `acc *= 2`.  
`key5 = acc & 0xFFFF`

---

## How the patcher works

A single byte is changed in the registration fail-path of `lordcfg.exe`:

```
File offset 0x749D  (virtual CS:0x1BBD)

Before: C6 06 18 02 00     mov [0x218], 0   ; fail = NOT registered
After:  C6 06 18 02 01     mov [0x218], 1   ; fail = registered
```

The success path already writes `1`; patching the fail path to also write `1`
means both branches produce the same outcome — registration always succeeds.

---

## Building from source

Requires [Free Pascal Compiler](https://www.freepascal.org/) 3.2.2 or later.

```bat
fpc lordkey.pas   -O2 -WG
fpc lordpatch.pas -O2 -WG
```

`-WG` selects the Windows GUI subsystem (no console window).

---

## Why I did this

I ordered valid keys from GamePort and never received a response.
This is posted for anyone who wants legitimate keys tied to their own
Sysop Name and BBS Name, or simply needs to get LORD running without
waiting on a defunct registration service.

---

## License

MIT — see [LICENSE](LICENSE).
