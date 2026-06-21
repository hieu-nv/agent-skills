---
name: win32-to-x64-migration-plan
description: 'Analyze a single C++/MFC method and produce a focused Win32→x64 migration plan for it. Reads the method body, its signature, the structs it touches, and its direct callers; classifies risks; then outputs a phased refactoring plan scoped to that one method. Use when the user names a specific function or method they want to port to x64.'
---

# Win32 → x64 Migration Plan — Method Scope (C++/MFC)

Produce a complete, risk-ranked migration plan for **one named method** before touching any code.
The plan covers only that method, the types it directly uses, and its immediate callers.

---

## Required Input

Before starting, you need:

| Input | How to get it |
|-------|---------------|
| **Method name** | Provided by the user (e.g. `CMainFrame::OnSerialize`) |
| **Source file** | Provided by the user, or locate with `grep -rn "MethodName" --include="*.cpp" .` |
| **Class name** | Inferred from the file or asked if ambiguous |

If any input is missing, ask for it before proceeding. Do not guess the source file.

---

## Core Principles

### Windows LLP64 Data Model Reference

| Type | 32-bit (ILP32) | 64-bit LLP64 | Notes |
|------|---------------|--------------|-------|
| `int` | 32-bit | **32-bit** | unchanged |
| `long` | 32-bit | **32-bit** | ⚠ differs from Linux LP64 |
| `long long` | 64-bit | **64-bit** | unchanged |
| pointer `*` | 32-bit | **64-bit** | primary source of bugs |
| `DWORD` | 32-bit | **32-bit** | safe for non-pointer values |
| `HANDLE` | 32-bit | **64-bit** | never truncate to DWORD |
| `SIZE_T` | 32-bit | **64-bit** | always use for sizes/counts |
| `WPARAM`/`LPARAM` | 32-bit | **64-bit** | message parameters widen |

### High-Risk Anti-Patterns

| # | Pattern | Safe replacement |
|---|---------|-----------------|
| 1 | Storing a pointer in `int` / `long` / `DWORD` / `UINT` | `INT_PTR`, `UINT_PTR`, `DWORD_PTR`, `uintptr_t` |
| 2 | Casting `HANDLE`/`HWND`/`HINSTANCE` to 32-bit integer | Keep as `HANDLE`, or `reinterpret_cast<ULONG_PTR>` |
| 3 | Hardcoded literal `4` as pointer size | `sizeof(void*)` |
| 4 | Struct member layout assumed (after a pointer field) | `static_assert(offsetof(...))` + explicit sizes |
| 5 | `__asm` block inside the method | `<intrin.h>` intrinsics or external `.asm` |
| 6 | `__stdcall`/`__cdecl`/`__fastcall` on function-pointer param | Remove decorator (x64 has one calling convention) |
| 7 | `LOWORD(wParam)` / `MAKELPARAM` carrying a pointer | `reinterpret_cast<T*>(wParam)` |
| 8 | `return (LONG)result;` in a `WNDPROC`-style method | `return (LRESULT)result;` |
| 9 | `sizeof(DWORD)` or `sizeof(int)` used as buffer stride | `sizeof(T)` for the actual element type |
| 10 | `time_t` cast to `long` | Cast to `__int64` / `long long` |

---

## Instructions

1. **Do not edit any file while preparing the plan.**
2. Locate and read the method body in full. Follow the investigation sequence below.
3. Classify every finding by severity: **Critical** / **High** / **Medium** / **Low** (see legend in Output Format).
4. Sequence the fixes from safest to riskiest:
   - Return-type / signature fixes first → local variable casts → struct members touched → caller-side adjustments → inline assembly → verification.
5. Each phase must include an explicit **Verify** step (what to compile or run to confirm correctness).
6. If the method touches a struct that is serialised or passed over IPC, add a rollback step for that phase.
7. Write the plan to a Markdown file named `WIN32_X64_<ClassName>_<MethodName>.md` beside the source file (or in `docs/x64/` if that directory exists).
8. After writing the file, stop and ask: **"Shall I proceed with Phase 1?"**

---

## Investigation Sequence

Run these steps in order. Limit all searches to the relevant source file and its direct headers unless a finding requires following a type into another file.

### Step 1 — Read the method body
```bash
# Find the method if the file is not provided
grep -rn "ClassName::MethodName" --include="*.cpp" .

# Then read the file at the relevant line range
# (use the Read tool on the returned file path)
```
Record: return type, every parameter type, every local variable type, every cast, every `sizeof`, every `__asm` block.

### Step 2 — Inspect the method signature in the header
```bash
grep -n "MethodName" path/to/ClassName.h
```
Record: declared return type, parameter types, calling-convention decorator if any.

### Step 3 — Check structs and types used inside the method
For each struct or typedef referenced in the method body:
```bash
grep -n "struct StructName\|typedef.*StructName\|using StructName" path/to/header.h
```
Record: any member that is a pointer, `HANDLE`, `HWND`, `DWORD`/`int` storing a pointer, or that affects binary layout.

### Step 4 — Find direct callers
```bash
grep -rn "MethodName\s*(" --include="*.cpp" --include="*.h" .
```
For each caller, note:
- How the return value is stored (is it cast to a 32-bit type?).
- What arguments are passed (are pointer-valued variables passed as `DWORD`?).
- Whether the caller is a message handler (`ON_MESSAGE`, `WM_*`) that widens `WPARAM`/`LPARAM`.

### Step 5 — Check for inline assembly in the method
```bash
grep -n "__asm" path/to/ClassName.cpp
```

### Step 6 — Check for calling-convention decorators
```bash
grep -n "__stdcall\|__cdecl\|__fastcall" path/to/ClassName.h path/to/ClassName.cpp
```

---

## Output Format

Write the plan to `WIN32_X64_<ClassName>_<MethodName>.md` using this structure.
Fill every section with findings from the investigation above; do not leave placeholder text.

```markdown
# Win32 → x64 Migration Plan — `ClassName::MethodName`

> **File:** `path/to/ClassName.cpp` (line N–M)
> **Date:** `<YYYY-MM-DD>`
> **Compiler target:** MSVC `<version>` / Windows SDK `<version>`

---

## 1. Method Snapshot

```cpp
// Current signature (32-bit)
ReturnType ClassName::MethodName(ParamType param1, ParamType2 param2);
```

[1–2 sentences describing what the method does and why it is risky to port.]

---

## 2. Risk Inventory

| # | Location | Pattern | Severity | Description |
|---|----------|---------|----------|-------------|
| 1 | line 42 | Pointer truncation | Critical | `DWORD hWnd = (DWORD)GetFocus()` — HWND widens to 64-bit |
| 2 | line 67 | sizeof misuse | High | `GlobalAlloc(0, 4)` — should be `sizeof(void*)` |
| … | … | … | … | … |

**Severity legend:**
- **Critical** — data corruption or crash at runtime on x64
- **High** — logic error, wrong value, silent truncation
- **Medium** — compiler warning, latent risk
- **Low** — style, future-proofing

---

## 3. Caller Impact

| Caller | File | Line | Impact | Action needed |
|--------|------|------|--------|---------------|
| `CApp::Init` | `App.cpp` | 88 | Stores return value as `DWORD` | Change to `DWORD_PTR` |
| `ON_MESSAGE(WM_FOO, OnFoo)` | `MainFrm.cpp` | 120 | `wParam` used as pointer | Use `reinterpret_cast<T*>(wParam)` |
| … | … | … | … | … |

---

## 4. Execution Plan

### Phase 1: Return Type & Signature
**Goal:** Fix the method's declared and defined return type and parameter types.

- [ ] 1.1 Change return type from `<old>` to `<new>` in `ClassName.h` line N.
- [ ] 1.2 Change return type in `ClassName.cpp` definition line M.
- [ ] 1.3 Update each caller listed in §3 to match the new return type.
- [ ] **Verify:** `cl /W4 /WX /c ClassName.cpp` (and each caller file) — zero C4311/C4312 errors.

---

### Phase 2: Local Variable Casts & sizeof Fixes
**Goal:** Eliminate all pointer-truncation casts and hardcoded size literals inside the method body.

- [ ] 2.1 Line N: replace `(DWORD)hWnd` with `reinterpret_cast<ULONG_PTR>(hWnd)`.
- [ ] 2.2 Line M: replace literal `4` with `sizeof(void*)`.
- [ ] 2.3 [repeat for each finding from Risk Inventory]
- [ ] **Verify:** Recompile the single `.cpp` file with `/W4 /WX`; all C4267/C4244 warnings in this file are gone.

---

### Phase 3: Struct Member Fixes (if applicable)
**Goal:** Correct any struct members that the method reads or writes and that change size on x64.

- [ ] 3.1 In `StructName` (`header.h` line N): change member `DWORD hWnd` → `HWND hWnd`.
- [ ] 3.2 Add layout assertions immediately after the struct definition:
  ```cpp
  static_assert(sizeof(StructName) == EXPECTED, "StructName layout changed for x64");
  static_assert(offsetof(StructName, field) == EXPECTED_OFF, "field offset changed");
  ```
- [ ] 3.3 If `StructName` is serialised: bump the format version constant and add an upgrade reader.
- [ ] **Verify:** `static_assert` compiles under x64 configuration. Serialisation round-trip test passes.
- [ ] **Rollback:** `git revert` struct change; restore previous format-version constant.

---

### Phase 4: Inline Assembly Replacement (if applicable)
**Goal:** Replace any `__asm` block inside the method — illegal under MSVC x64.

- [ ] 4.1 Line N: replace `__asm { ... }` with `<intrinsic or Win32 API>` from `<intrin.h>`.
- [ ] **Verify:** `grep -n "__asm" ClassName.cpp` returns zero hits. x64 build completes without C2415.

---

### Phase 5: Calling-Convention Cleanup (if applicable)
**Goal:** Remove or correct obsolete decorators that could silently misfire on x64.

- [ ] 5.1 Remove `__stdcall` / `__cdecl` from the method signature (x64 has one ABI).
- [ ] 5.2 If the method is exported `extern "C"`, keep the decorator — it affects name mangling.
- [ ] **Verify:** No new C4229 warnings. Any function-pointer typedef that references this method still type-checks.

---

### Phase 6: Verification
**Goal:** Confirm the method is correct end-to-end under x64.

- [ ] 6.1 Compile the affected TUs with `/W4 /WX /analyze` targeting x64 — zero new defects.
- [ ] 6.2 Run the unit tests that exercise `MethodName` directly: `<test command>`.
- [ ] 6.3 If no unit tests cover this method, add a minimal smoke test that calls it and asserts the return value.
- [ ] 6.4 Run Application Verifier (**Basics** layer) on the x64 binary and exercise the code path — no heap or handle errors.

---

## 5. Rollback Plan

1. `git revert <commit-range-for-this-plan>` — keep history auditable.
2. Re-run the x86 test suite to confirm no regression: `msbuild /p:Platform=Win32 && ctest -C Release`.
3. If a struct layout change was reverted, also restore the previous format-version constant.

---

## 6. Open Questions

- [ ] Does `StructName` need to remain binary-compatible with 32-bit readers? *(clarify before Phase 3)*
- [ ] Is `ClassName::MethodName` exported from a DLL? *(affects whether calling-convention must be kept)*
- [ ] Are there callers in code not yet found by grep (generated code, reflection, scripting bindings)?
```

---

## Copilot Directives

- **Scope is strictly one method.** Do not grep the whole repository; limit all searches to the source file, its direct headers, and files that call the method.
- Do not edit any file while preparing the plan.
- Name the output file `WIN32_X64_<ClassName>_<MethodName>.md`. Place it next to the source file unless a `docs/x64/` directory exists, in which case place it there.
- Omit any phase that has no findings (e.g. if there is no `__asm`, skip Phase 4 entirely — do not include it with a "N/A" note).
- If the method is a `WNDPROC`, `DialogProc`, or MFC message handler, prepend a note in §1 warning that `WPARAM`/`LPARAM` widen on x64 and that the return type must be `LRESULT`, not `LONG`.
- If no unit tests cover this method, add a **Critical** process risk to §2 and make Phase 6 step 6.3 mandatory.
- After writing the file, print exactly: **"Migration plan written to `WIN32_X64_<ClassName>_<MethodName>.md`. Shall I proceed with Phase 1?"**
