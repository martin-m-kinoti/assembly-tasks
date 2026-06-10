# Flag Analysis — `calc.asm`

This document walks through how `calc` sets `CF`, `ZF`, `SF`, and `OF` for each
operation, using the values from [screenshots/Screenshot 2026-06-10 121344.png](screenshots/Screenshot%202026-06-10%20121344.png)
(`a = 1`, `b = 3`) as a baseline, plus extra inputs chosen to demonstrate flags
that the baseline doesn't trigger.

| Flag | Meaning |
|------|---------|
| CF | Unsigned carry/borrow out of the result, or MUL/IMUL overflow into the high half |
| ZF | Result is exactly zero |
| SF | Result's most significant bit is 1 (negative in two's complement) |
| OF | Signed result overflowed the destination's signed range |

## ADD — `a + b`

- `1 + 3 = 4` → `CF=0 ZF=0 SF=0 OF=0` (fits easily in a byte, no overflow).
- `200 + 100 = 300` (would need 9 bits) → `CF=1`, since the unsigned result
  doesn't fit in 8 bits.
- `100 + 100 = 200` → `OF=1`, because two positive operands (in signed
  interpretation) produced a negative result (`200` as a signed byte is `-56`).

## SUB — `a - b`

- `1 - 3 = -2` → `CF=1` (borrow occurred, since `1 < 3` unsigned),
  `SF=1` (result is negative), `OF=0` (no signed overflow — result `-2` fits
  in a signed byte).
- `5 - 5 = 0` → `ZF=1`, `CF=0`, `SF=0`.

## INC(a) — `a + 1`

- `1 + 1 = 2` → `ZF=0 SF=0 OF=0`. **`CF` is left unchanged by `INC`** — it
  always reflects whatever the previous operation set, since `INC` does not
  touch `CF` (this is documented in the program output via the `CF` value
  carried over from the prior op).
- `127 + 1 = 128` → `OF=1 SF=1`, since `128` overflows the signed byte range
  (`-128..127`) and its top bit is set.

## DEC(a) — `a - 1`

- `1 - 1 = 0` → `ZF=1 SF=0 OF=0`. Like `INC`, `CF` is unaffected by `DEC`.
- `0 - 1 = -1` (wraps to `0xFF`) → `SF=1 OF=0`, `CF` still unchanged.

## MUL — unsigned `AX = AL * BL`

From the screenshot: `1 * 3 = 3` → `CF=0 ZF=0 SF=0 OF=0`, because the product
fits entirely in `AL` (`AH = 0`).

- `100 * 3 = 300 = 0x012C` → `AH != 0`, so `CF=1` and `OF=1`. `MUL` does not
  define `ZF`/`SF` meaningfully, but the simulator still reports whatever bits
  6/7 of `RFLAGS` happen to hold.

## IMUL — signed `rax = rax * rbx`

- `1 * 3 = 3` → `CF=0 OF=0` (result fits in `rax` with no sign change beyond
  what's representable).
- `9 * 9 = 81` → still fits in 64 bits, so `CF=0 OF=0`. `IMUL rax, rbx` only
  sets `CF`/`OF` when the full 128-bit product doesn't fit back into 64 bits,
  which is effectively unreachable with single-digit (0-9) inputs.

## DIV — unsigned `AL = AX / BL`, `AH = remainder`

- `1 / 3 = 0` remainder `1` → `ZF=1` (quotient is zero), `CF=0 OF=0`
  (`DIV` always clears/undefines arithmetic flags in a way the simulator
  reads as 0 here).
- `b = 0` → caught before the `div` instruction executes (`[!] Division by
  zero.`), so no flags are produced — `div` by zero would otherwise raise a
  `#DE` exception and crash the program.

## IDIV — signed `AL = AX / BL`, `AH = remainder`

- `1 / 3 = 0` remainder `1` → `ZF=1`, same reasoning as `DIV`.
- `b = 0` → guarded the same way as `DIV`, printing `[!] Division by zero.`.

## AND — `a & b`

From the screenshot: `1 AND 3 = 1` (`0b001 & 0b011 = 0b001`) →
`CF=0 ZF=0 SF=0 OF=0`. `AND` always **clears `CF` and `OF`**, and sets
`ZF`/`SF` from the result.

- `1 AND 0 = 0` → `ZF=1`, `CF=0 OF=0`.

## OR — `a | b`

- `1 OR 3 = 3` (`0b001 | 0b011 = 0b011`) → `ZF=0 SF=0`, `CF=0 OF=0` (cleared,
  same as `AND`).
- `0 OR 0 = 0` → `ZF=1`.

## XOR — `a ^ b`

- `1 XOR 3 = 2` (`0b001 ^ 0b011 = 0b010`) → `ZF=0 SF=0`, `CF=0 OF=0`.
- `3 XOR 3 = 0` → `ZF=1` (any value XOR'd with itself is zero — also clears
  `CF`/`OF`).

## NOT(a) — `~a`

`NOT` is documented (and verified) to leave **all flags unchanged** —
whatever `CF/ZF/SF/OF` were set by the previous operation are simply
re-displayed. E.g. `NOT 1 = 0xFE` (`-2` as a signed byte) prints flags
identical to the prior instruction's flags.

## TEST — `a AND b` (flags only)

Same flag rules as `AND` (`CF=0 OF=0`, `ZF`/`SF` from `a & b`), but the
result of the `AND` is discarded — only the flags are kept. With the
baseline values, `1 TEST 3` → `ZF=0 SF=0 CF=0 OF=0`.

## Summary table (baseline a=1, b=3)

| Op | Result | CF | ZF | SF | OF |
|----|--------|----|----|----|----|
| ADD | 4 | 0 | 0 | 0 | 0 |
| SUB | -2 | 1 | 0 | 1 | 0 |
| INC(a) | 2 | unchanged | 0 | 0 | 0 |
| DEC(a) | 0 | unchanged | 1 | 0 | 0 |
| MUL | 3 | 0 | 0 | 0 | 0 |
| IMUL | 3 | 0 | 0 | 0 | 0 |
| DIV | 0 r1 | 0 | 1 | 0 | 0 |
| IDIV | 0 r1 | 0 | 1 | 0 | 0 |
| AND | 1 | 0 | 0 | 0 | 0 |
| OR | 3 | 0 | 0 | 0 | 0 |
| XOR | 2 | 0 | 0 | 0 | 0 |
| NOT(a) | -2 | unchanged | unchanged | unchanged | unchanged |
| TEST | (1, discarded) | 0 | 0 | 0 | 0 |
