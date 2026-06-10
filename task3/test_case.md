# Test Cases — Boundary Marks

`marks.asm` classifies each mark with two `cmp ... jge` chains:

```asm
cmp al, DIST_MIN   ; DIST_MIN = 70
jge .is_dist
cmp al, CRED_MIN   ; CRED_MIN = 60
jge .is_cred
cmp al, PASS_MIN   ; PASS_MIN = 40
jge .is_pass
inc r12b           ; else: fail
```

Because every comparison uses `jge` (`>=`), the boundary itself belongs to
the **higher** band (e.g. exactly `70` is Distinction, not Credit). The six
boundary values below are baked into the `marks` array specifically to
exercise both sides of each cutoff in a single run.

## Boundary value matrix

| Mark | Array position | Cutoff being tested | Expected band | Reasoning |
|-----:|-----------------|----------------------|----------------|-----------|
| `0`   | `marks[8]`  | absolute minimum            | Fail        | `0 < 40` → falls through to `inc r12b`. Also must become the new `lowest` (`r10b`). |
| `39`  | `marks[7]`  | `PASS_MIN - 1` (just below 40) | Fail     | `39 < 40` → fails the `cmp al, PASS_MIN / jge` test, falls through to Fail. Confirms the boundary is **exclusive** on the low side. |
| `40`  | `marks[6]`  | `PASS_MIN` (= 40)            | Pass        | `40 >= 40` → `jge .is_pass` taken. Confirms the boundary is **inclusive**. |
| `69`  | `marks[11]` | `DIST_MIN - 1` (just below 70) | Credit   | `69 < 70` → fails `cmp al, DIST_MIN / jge`, but `69 >= 60` → `jge .is_cred` taken. |
| `70`  | `marks[10]` | `DIST_MIN` (= 70)            | Distinction | `70 >= 70` → `jge .is_dist` taken on the **first** comparison. |
| `100` | `marks[4]`  | absolute maximum             | Distinction | `100 >= 70` → Distinction. Also must become the new `highest` (`r9b`). |

## Expected program output

With the array `45, 72, 38, 91, 100, 67, 40, 39, 0, 55, 70, 69`
(total = 686, average = 686 / 12 = 57):

```
=== Mark Statistics ===
Marks      : 45, 72, 38, 91, 100, 67, 40, 39, 0, 55, 70, 69
Total      : 686
Average    : 57
Highest    : 100
Lowest     : 0

--- Grade Bands ---
Distinction (70-100) : 4
Credit      (60-69)  : 2
Pass        (40-59)  : 3
Fail        ( 0-39)  : 3
```

### Band membership check

| Band | Members | Count |
|------|---------|------:|
| Distinction (>=70) | 72, 91, 100, 70 | 4 |
| Credit (60-69) | 67, 69 | 2 |
| Pass (40-59) | 45, 40, 55 | 3 |
| Fail (<40) | 38, 39, 0 | 3 |

`4 + 2 + 3 + 3 = 12 = MCOUNT` ✓ — every mark lands in exactly one band.

## Verifying with GDB

A debug build (`marks_dbg`, built with `-g -F dwarf`) lets each boundary be
single-stepped to confirm the branch taken:

```bash
gdb ./marks_dbg
```

```gdb
break .classify
run

# each time the breakpoint hits, AL holds the current mark
info registers al

# step through the cmp/jge chain and confirm the branch
stepi
info registers eflags    # CF=0 and ZF=1 together mean AL == cutoff (>=)
```

Expected `eflags` behaviour at each boundary, just before the jump that
decides its band (checking `cmp al, PASS_MIN` for 39/40 and
`cmp al, DIST_MIN` for 69/70):

| Mark | Comparison | ZF | CF | `jge` taken? | Result |
|-----:|------------|----|----|--------------|--------|
| 39 | `cmp al, 40` | 0 | 1 | no (`39 < 40`) | falls to Fail |
| 40 | `cmp al, 40` | 1 | 0 | yes (`40 >= 40`) | Pass |
| 69 | `cmp al, 70` | 0 | 1 | no (`69 < 70`), then `cmp al, 60` → yes | Credit |
| 70 | `cmp al, 70` | 1 | 0 | yes (`70 >= 70`) | Distinction |

For `0` and `100`, also confirm the running min/max registers update:

```gdb
# after the loop finishes, r9b should hold 100 and r10b should hold 0
break _start+ <addr after .stat_loop>
continue
print/d $r9b   # expect 100 (highest)
print/d $r10b  # expect 0   (lowest)
```

## Edge case not present in the array

If `marks` contained a value `> 100` or treated as negative (signed byte
`< 0`), the `cmp al, ...` comparisons would still behave correctly for
**unsigned** thresholds because `jge`/`jl` here operate on values compared
with `cmp`, which sets flags based on unsigned subtraction for the
constants used (`40`, `60`, `70` are all small positive immediates well
within byte range, so signed/unsigned interpretation does not diverge for
any valid 0–100 mark).
