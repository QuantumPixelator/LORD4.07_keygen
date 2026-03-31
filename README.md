# LORD v4.07 — Registration Keygen & Patcher

Registration key generator and binary patcher for **Legend of the Red Dragon (LORD) v4.07**,
a classic BBS door game by Seth Able Robinson / Metropolis Inc., circa 2006.

Both a **Windows GUI** (`.exe`) and a **Python CLI** version are provided for each tool.
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

### Generating Your VALID KEYS that you PAID the author(s) for:

- Run the GUI app (lordkey.exe)
- Or open the source code in Python and run it 'python3 lordkey.py "Sysop Name" "BBS Name"'

If you just want your registration keys without any effort, go here:
[LORD Key Online Generator](http://192.3.16.80:8085)

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
