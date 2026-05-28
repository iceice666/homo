type config = {
  cli_path : string;
  model : string option;
}

type t = config

let of_config cfg = Ok cfg

let stream_message _t ~history:_ ~user_msg:_ _on_token =
  (* TODO: spawn `claude -p "<prompt>"`, stream stdout line-by-line via Unix pipe *)
  Lwt.return (Error "claude-cli adapter: not yet implemented")
