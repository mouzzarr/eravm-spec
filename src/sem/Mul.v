Require sem.SemanticCommon.

Import Bool Core Modifiers Common Flags isa.CoreSet CallStack Memory MemoryOps State ZMod
  ZArith PrimitiveValue SemanticCommon List ListNotations.

Section Def.
  Open Scope ZMod_scope.

  Generalizable Variables tag.

  Inductive step_mul: instruction -> flags_tsmallstep :=
(**
# Mul

## Abstract Syntax

```
OpMul (in1: in_any) (in2: in_reg) (out1: out_any) (out2: out_any)
      (swap:mod_swap) (flags:mod_set_flags)
```

## Syntax

- `mul in1, in2, out1, out2`
- `mul.s in1, in2, out1, out2`, to set `swap` modifier.
- `mul! in1, in2, out1, out2`, to set `set flags` modifier.
- `mul.s! in1, in2, out1, out2`, to set both `swap` and `set flags` modifiers.

## Summary

Unsigned overflowing multiplication of two numbers modulo $2^{512}$; the high and low 256 bits of the result are returned in two separate operands.

## Semantic

1. Resolve `in1` and apply its addressing effects, resolve `in2`, resolve `out1` and apply its addressing effects, resolve `out2`.

2. Compute result by unsigned multiplication of `in1` by `in2`.

   $$\begin{cases}result_{high} := \frac{ op_1 \times op_2}{2^{256}}\\
result_{low} := op_1 \times op_2 \mod 2^{256} \end{cases}$$

3. Flags are computed as follows:
   - `LT_OF` is set if overflow occurs, i.e. $op_1 \times op_2 \geq 2^{256}$
   - `EQ` is set if $result_{low} = 0$.
   - `GT` is set if `LT_OF` and `EQ` are cleared.

   Reminder: flags are only set if `set_flags` modifier is set.

4. Wtore results in the locations corresponding to `out1` and `out2`.

## Affected parts of VM state

- execution stack: PC, as by any instruction; SP, if `in1` uses `RelPop` addressing mode, or if `out1` uses `RelPush` addressing mode.
- Current stack memory page, if `out` resolves to it.
- GPRs, by `out2` and `out1`, provided `out1` resolves to GPR.
- flags, if `set_flags` modifier is set.

## Usage

Arithmetic operations.

## Similar instructions

- See [%OpDiv].

 *)
  | step_Mul:
    forall mod_sf old_flags new_flags w_high w_low high low (x y:Z) op1 op2,
      `(
          let x := int_val _ op1 in
          let y := int_val _ op2 in
          extract_digits (x * y) word_bits 2 = [ w_high;  w_low ] ->
          let high256 := u256_of w_high in
          let low256  := u256_of w_low in

          let new_EQ := low256  == zero256 in
          let new_OF := high256 != zero256 in
          let new_GT := negb new_EQ && negb new_OF in

          new_flags = apply_set_flags mod_sf old_flags
                        (bflags new_OF new_EQ new_GT) ->

          step_mul (OpMul (mk_pv tag1 op1) (mk_pv tag2 op2) (IntValue high) (IntValue low) mod_sf) old_flags new_flags
        ).
  Generalizable No Variables.
End Def.
