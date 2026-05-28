type config = {
  api_key : string;
  model : string;
  max_tokens : int;
  system_prompt : string option;
}

type t = config

let of_config cfg =
  if cfg.api_key = "" then Error "ANTHROPIC_API_KEY not set"
  else Ok cfg

let stream_message _t ~history:_ ~user_msg:_ _on_token =
  (* TODO: POST to https://api.anthropic.com/v1/messages with stream:true,
     parse SSE content_block_delta events, call on_token for each delta.text *)
  Lwt.return (Error "claude-api backend: not yet implemented")
