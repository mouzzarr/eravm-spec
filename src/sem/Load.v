From RecordUpdate Require Import RecordSet.

Require SemanticCommon Addressing.

Import ABI Addressing Bool Common Condition CallStack Memory MemoryOps Instruction State ZMod
  Addressing.Coercions SemanticCommon Pages State RecordSetNotations ZMod.

Import FatPointer.
Import List ListNotations.

Section Defs.
  
  Context (old_regs: regs_state) (old_xstack: callstack) (old_pages:memory).
  Let fetch := resolve_load old_xstack (old_regs, old_pages).
  Let fetch_word := resolve_load_word old_xstack (old_regs,old_pages).
  Let stores := resolve_stores old_xstack (old_regs,old_pages).
  
  Inductive step_load : instruction -> 
                        regs_state * callstack * memory-> Prop :=
  (**
# Load


## Abstract Syntax

```
OpLoad (ptr: in_regimm) (res: out_reg) (mem:data_page_type)
```

## Syntax

- `uma.heap_read in1, out` aliased as `ld.1 in1, out`
- `uma.aux_heap_read in1, out` aliased as `ld.2 in1, out`


## Summary

Load 32 consecutive bytes from address `ptr` of active `heap` or `aux_heap` page.

## Semantic

1. Decode a fat pointer `in_ptr` from `ptr`.

   Fat pointers have following fields:

```
Record fat_ptr :=
  mk_fat_ptr {
      fp_page: page_id;
      fp_start: mem_address;
      fp_length: mem_address;
      fp_offset: mem_address;
    }.
```

2. Ensure reading 32 consecutive bytes is possible; it is impossible if $\texttt{fp\_offset} > 2^{32}-32$.

   Note: Valid (aux_)heap fat pointers always have `fp_start = 0`, therefore the read starts from an absolute address `fp_offset` in heap/auxheap. See [fat_ptr].

3. If  `fp_offset + 32 > (aux_)heap bound`, grow (aux_)heap bound and pay for the growth. We are aiming at reading a 256-bit word starting from address `fp_offset`, so the (aux_)heap bound should contain all of it.
4. Read 32 consecutive bytes as a Big Endian 256-bit word from address `fp_offset` in (aux_)heap.
5. Store this word to `res`.
*)
  | step_Load:
    forall new_xstack heap_variant enc_ptr (arg_dest:out_reg) (arg_enc_ptr:in_regimm) result new_regs new_pages selected_page in_ptr query,

      fetch_word arg_enc_ptr enc_ptr ->
      ABI.(decode) enc_ptr = Some in_ptr ->
      let used_ptr := in_ptr <| fp_page := heap_variant_id heap_variant old_xstack |> in

      (* In Heap/Auxheap, 'start' of the pointer is always 0, so offset = absolute address *)
      let addr := used_ptr.(fp_offset) in
      addr <= MAX_OFFSET_TO_DEREF_LOW_U32 = true ->
      
      heap_variant_page _ heap_variant old_pages old_xstack (DataPage _ selected_page) ->
      load_result BigEndian selected_page addr result ->

      word_upper_bound used_ptr query ->
      grow_and_pay heap_variant query old_xstack new_xstack ->

      stores [
          (OutReg arg_dest, IntValue result)
        ] (new_regs, new_pages) ->

      step_load (OpLoad arg_enc_ptr arg_dest heap_variant)
        (new_regs, new_xstack, new_pages)
  .
(**
## Affected parts of VM state

- execution stack:

  + PC, as by any instruction;
  + ergs balance if the (aux_)heap has to be grown;
  + (aux_)heap bounds, if (aux_)heap has to be grown.

- GPRs, because `res` only resolves to a register.

## Usage

- Only [OpLoad] and [OpLoadInc] are capable of reading data from heap/aux_heap.
- One of few instructions that accept only reg or imm operand but do not have full addressing mode, therefore can't e.g. address stack. The full list is: [OpLoad], [OpLoadInc], [OpStore], [OpStoreInc], [OpLoadPointer], [OpLoadPointerInc].

## Similar instructions

- [OpLoad], [OpLoadInc], [OpStore], [OpStoreInc], [OpLoadPointer], [OpLoadPointerInc] are variants of the same instruction.

 *)
End Defs.
