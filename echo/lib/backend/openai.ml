type config = {
  api_key : string;
  model : string;
  max_tokens : int;
  system_prompt : string option;
}

type t = config

let of_config cfg =
  if cfg.api_key = "" then Error "OPENAI_API_KEY not set"
  else Ok cfg

let stream_message _t ~history:_ ~user_msg:_ _on_token =
  (* TODO: POST to https://api.openai.com/v1/chat/completions with stream:true,
     parse SSE choices[0].delta.content chunks, call on_token *)
  Lwt.return (Error "openai backend: not yet implemented")
