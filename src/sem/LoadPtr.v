Require SemanticCommon Addressing.

Import ABI Addressing Common CallStack Memory MemoryOps Instruction ZMod
  Addressing.Coercions SemanticCommon Pages State .

Import FatPointer.
Import List ListNotations.
Import Addressing.Coercions.


Section Defs.
  
  Context (old_regs: regs_state) (old_xstack: callstack) (old_pages:memory).
  Let fetch := resolve_load old_xstack (old_regs, old_pages).
  Let fetch_word := resolve_load_word old_xstack (old_regs,old_pages).
  Let stores := resolve_stores old_xstack (old_regs,old_pages).
    
  Inductive step_load_ptr : instruction -> 
                            regs_state * memory -> Prop :=
                    
  | step_LoadPointer:
    forall enc_ptr (arg_dest: out_reg) (arg_enc_ptr: in_reg) result new_regs new_pages addr selected_page in_ptr slice,

      fetch arg_enc_ptr (PtrValue enc_ptr) ->
      ABI.(decode) enc_ptr = Some in_ptr ->

      validate_in_bounds in_ptr = true ->
      
      page_has_id _ old_pages in_ptr.(fp_page) (DataPage _ selected_page) ->
      slice_from_ptr selected_page in_ptr slice ->
      
      (addr, false) = in_ptr.(fp_start) + in_ptr.(fp_offset) ->
      load_slice_result BigEndian slice addr result ->
      
      stores [
        (OutReg arg_dest, IntValue result)
        ] (new_regs, new_pages) ->

      step_load_ptr (OpLoadPointer arg_enc_ptr arg_dest) (new_regs, new_pages)
  .
End Defs.