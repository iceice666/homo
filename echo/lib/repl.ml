open Lwt.Syntax

(* Readline REPL using lambda-term. Streams tokens from the active backend
   and renders them incrementally. *)

let run ~config:_ ~backend:_ =
  (* TODO: open LTerm terminal, enter raw mode, start prompt loop *)
  let* () = Lwt_io.printl "echo REPL: not yet implemented" in
  Lwt.return_unit
