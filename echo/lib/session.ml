type state = {
  session_id : string;
  profile : string;
  messages : Message.t list;
  backend : string;
  model : string option;
}

let empty ~session_id ~profile ~backend =
  { session_id; profile; messages = []; backend; model = None }

let add_message state msg =
  { state with messages = state.messages @ [msg] }

(* TODO: persist to ~/.config/echo/profiles/<profile>/sessions/<id>.json *)
let save _state = Ok ()

(* TODO: load from ~/.config/echo/profiles/<profile>/sessions/<id>.json *)
let load ~session_id:_ ~profile:_ ~backend:_ = Ok (empty ~session_id:"" ~profile:"" ~backend:"")
