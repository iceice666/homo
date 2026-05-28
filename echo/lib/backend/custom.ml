type config = {
  base_url : string;
  model : string;
  api_key : string option;
  system_prompt : string option;
}

type t = config

let of_config cfg =
  if cfg.base_url = "" then Error "backend.custom.base_url not set"
  else Ok cfg

let stream_message _t ~history:_ ~user_msg:_ _on_token =
  (* TODO: OpenAI-compatible endpoint at base_url; same SSE parsing as openai.ml *)
  Lwt.return (Error "custom backend: not yet implemented")
