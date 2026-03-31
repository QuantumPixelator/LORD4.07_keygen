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
