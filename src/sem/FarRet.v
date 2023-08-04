From RecordUpdate Require Import RecordSet.

Require
ABI
Bool
CallStack
Coder
Common
Flags
GPR
MemoryContext
Pointer
PrimitiveValue
SemanticCommon
State.

Import
ABI
ABI.FatPointer
Bool
CallStack
Coder
Common
Flags
GPR
isa.CoreSet
MemoryContext
Pointer
PrimitiveValue
RecordSetNotations
SemanticCommon
State
.

Section FarRet.

  Inductive step_farret: instruction -> tsmallstep :=
(**

# Far return (normal return, not panic/revert)

## Abstract Syntax

[%OpFarRet (args: in_reg)]

## Syntax

`ret abi_reg`

  A normal return from a **far** call. Will pop up current callframe, give back unspent ergs and
  continue execution from the saved return address (from where the call had taken place).
  The register `abi_reg` describes a span of memory passed to the external caller.

  The assembler expands `ret` to `ret r1`; `r1` is ignored by returns from near calls.

## Semantic

1. Fetch the value from register `abi_reg` and decode the value of type [%fwd_memory]:

```
Inductive fwd_memory :=
  ForwardFatPointer (p:fat_ptr)
| ForwardNewHeapPointer (heap_var: data_page_type) (s:span).
```

   The exact encoding is described by ABI.

2. Forward a memory span to the caller (see [%paid_forward]):
   - For [%ForwardFatPointer p]:
      + ensure that the register containing `abi_reg`  is tagged as pointer.
      + ensure that the memory page of `p` does NOT refer to a page owned by an older frame.
      + [%fp_narrow] [%p] so it starts at its current offset, and the offset is reset to zero. See [%free_ptr_narrow].

        TODO Explanation why the circularity check is necessary.

     There is no payment because the existing fat pointer has already been paid for.

   - For [%ForwardNewHeapPointer heap_var (start, limit)]:
      + let $B$ be the bound of the heap variant [%heap_var] taken from
        [%ctx_heap_bound] field of [%ecf_mem_ctx] of the active external frame.
      + let $I$ be the page id of the heap variant [%heap_var] taken from
        [%ctx_heap_page_id] field of [%ecf_mem_ctx] of the active external frame.
      + form a fat pointer $P$ from the span as described in
        [%paid_forward_heap_span].

         $$P := (I, (\mathit{addr}, \mathit{length}), 0)$$

      + if $\mathit{start} + \mathit{limit} >B$, pay for the growth difference
        ([%growth_cost] $(\mathit{start} + \mathit{limit} - B)$).

     Note: it is not useful to readjust the current heap/auxheap bounds after
     paying for growth. The bounds are part of [%mem_ctx] of the topmost frame, which is about to be discarded.

3. Return the remaining ergs to the caller.
4. Clear flags.
5. Encode $P$ and store it in register [%r1], setting its pointer tag.

   All other registers are zeroed. Registers [%r2], [%r3], and [%r4] are
   reserved and may gain a special meaning in newer versions of EraVM.
 6. Context register is zeroed.
*)
| step_RetExt_heapvar:
  forall pages cf caller_stack cs1 caller_reimbursed enc  ___ ____ _____ out_ptr heap_type hspan params s1 s2,
    let cs0 := ExternalCall cf (Some caller_stack) in

    paid_forward_heap_span heap_type (hspan, cs0) (out_ptr, cs1) ->
    ergs_reimburse_caller_and_drop cs1 caller_reimbursed ->
    params = FarRet.mk_params (ForwardNewHeapPointer heap_type hspan) ->
    step_transient_only {|
                          gs_flags        := ___ ;
                          gs_callstack    := cs0;
                          gs_regs         := ____;
                          gs_context_u128 := _____;


                          gs_pages        := pages;
                        |}
                        {|
                          gs_flags        := flags_clear;
                          gs_callstack    := caller_reimbursed;
                          gs_regs         := regs_state_zero
                             <| r1 := PtrValue (encode_fat_ptr out_ptr) |>
                             <| r2 := reserved |>
                             <| r3 := reserved |>
                             <| r4 := reserved |> ;
                          gs_context_u128 := zero128;


                          gs_pages        := pages;
                           |} s1 s2 ->
    step_farret (OpFarRet (Some params, enc)) s1 s2 

  | step_RetExt_ForwardFatPointer:
  forall pages cf caller_stack cs1 caller_reimbursed __ ___ ____ in_ptr out_ptr page params enc s1 s2,
    let cs0 := ExternalCall cf (Some caller_stack) in

    in_ptr.(fp_page) = Some page ->

    page_older page (get_mem_ctx cs0) = false->

    validate in_ptr = no_exceptions ->

    fat_ptr_narrow in_ptr out_ptr ->

    ergs_reimburse_caller_and_drop cs1 caller_reimbursed ->
    params = FarRet.mk_params (ForwardFatPointer in_ptr) ->
    step_transient_only {|
                          gs_flags        := __ ;
                          gs_callstack    := cs0;
                          gs_regs         := ___;
                          gs_context_u128 := ____;


                          gs_pages        := pages;
                        |}
                        {|
                          gs_flags        := flags_clear;
                          gs_callstack    := caller_reimbursed;
                          gs_regs         := regs_state_zero
                             <| r1 := PtrValue (encode_fat_ptr out_ptr) |>
                             <| r2 := reserved |>
                             <| r3 := reserved |>
                             <| r4 := reserved |> ;


                          gs_context_u128 := zero128;
                          gs_pages        := pages;
                          |} s1 s2 ->
    step_farret (OpFarRet (Some params, enc)) s1 s2
  .

(**

## Affected parts of VM state

- Flags are cleared.
- Context register is zeroed (only returns from far calls).
- Registers are cleared (only returns from far calls).
- Execution stack:
  + Current frame is dropped.
  + Caller frame:
    * Unspent ergs are given back to caller (but memory growth is paid first).

## Usage

## Similar instructions

- `revert` executes the current frame's exception handler instead of returning
  to the caller.
- `panic` executes the current frame's exception handler instead of returning to
  the caller, and sets overflow flag.


*)
End FarRet.
