From RecordUpdate Require Import RecordSet.

Require SemanticCommon Addressing.


Import ABI Addressing Bool Common Condition CallStack Memory MemoryOps Instruction State ZMod
  Addressing.Coercions SemanticCommon Pages State RecordSetNotations ZArith ZMod.

Import FatPointer.
Import List ListNotations.
Import Addressing.Coercions.


Section Defs.
  
  Context (old_regs: regs_state) (old_xstack: callstack) (old_pages:memory).
  Let fetch := resolve_load old_xstack (old_regs, old_pages).
  Let fetch_word := resolve_load_word old_xstack (old_regs,old_pages).
  Let stores := resolve_stores old_xstack (old_regs,old_pages).
  
  Inductive step_store: instruction -> regs_state * callstack * memory -> Prop :=

  | step_StoreInc:
    forall new_xstack heap_variant enc_ptr (arg_modptr:out_reg) (arg_enc_ptr:in_regimm) (arg_val:in_reg) value new_regs new_pages selected_page in_ptr ptr_incremented pages1 query modified_page,

      let selected_page_id := heap_variant_id heap_variant old_xstack in

      fetch_word arg_enc_ptr enc_ptr ->
      fetch_word arg_val value ->
      
      ABI.(decode) enc_ptr = Some in_ptr ->
      
      let used_ptr := in_ptr <| fp_page := selected_page_id |> in
      
      (* In Heap/Auxheap, 'start' of the pointer is always 0, so offset = absolute address *)
      let addr := used_ptr.(fp_offset) in
      addr <= MAX_OFFSET_TO_DEREF_LOW_U32 = true ->
      
      heap_variant_page _ heap_variant old_pages old_xstack (DataPage _ selected_page) ->

      word_upper_bound used_ptr query ->
      grow_and_pay heap_variant query old_xstack new_xstack ->

      
      ptr_inc used_ptr ptr_incremented  ->
      
      stores
        [
          (OutReg arg_modptr, PtrValue (ABI.(encode) ptr_incremented))
        ]
        (new_regs, pages1) ->

      store_word_result BigEndian selected_page addr value modified_page ->
      page_replace _ selected_page_id (DataPage _ modified_page) pages1 new_pages ->

      step_store (OpStoreInc arg_enc_ptr arg_val heap_variant arg_modptr)
        (new_regs, new_xstack, new_pages)
  .

End Defs. 