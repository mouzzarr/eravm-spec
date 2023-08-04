Require SemanticCommon.

Import Common Flags CallStack isa.CoreSet State SemanticCommon.

Section NearRetTo.
  Generalizable Variables __ regs pages ctx.
  Inductive step_nearretto: @instruction bound -> tsmallstep :=
  (**

# NearRetTo (normal return to label, not panic/revert)

## Abstract Syntax

- [%OpNearRetTo (label: code_address)]

## Syntax

- `ret label`

  A normal return from a **near** call. Will pop up current callframe, give back unspent ergs and
  continue execution from an explicitly provided label.

  The assembler expands `ret` to `ret r1`, but `r1` is ignored by returns from near calls.


## Semantic

1. Pass all ergs from the current frame to the parent frame.
2. Drop current frame.
3. Clear flags
4. Set PC to the label value.
   *)
  | step_NearRetTo:
    forall cf caller_stack caller_reimbursed label,
      `(
          ergs_reimburse_caller_and_drop (InternalCall cf caller_stack) caller_reimbursed ->

          step_nearretto (OpNearRetTo label) {|
                     gs_flags        := __;
                     gs_callstack    := InternalCall cf caller_stack;


                     gs_regs         := regs;
                     gs_pages        := pages;
                     gs_context_u128 := ctx;
                   |}
                   {|
                     gs_flags        := flags_clear;
                     gs_callstack    := pc_set label caller_reimbursed;


                     gs_regs         := regs;
                     gs_pages        := pages;
                     gs_context_u128 := ctx;
                   |}
        )
  .
  (**

## Affected parts of VM state

- Flags are cleared.
- Execution stack:
  + Current frame is dropped.
  + Caller frame:
    * Unspent ergs are given back to caller (but memory growth is paid first).
    * program counter is assigned the label.

## Usage

Normal return from functions.
   *)
  Generalizable No Variables.
End NearRetTo.
