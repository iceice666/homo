type stream_fn =
  history:Message.t list -> user_msg:string -> (string -> unit) -> (unit, string) result Lwt.t

type entry = {
  name : string;
  stream : stream_fn;
}

let not_impl name ~history:_ ~user_msg:_ _on_token =
  Lwt.return (Error (name ^ ": not yet implemented"))

let all = [
  { name = "claude-cli";  stream = not_impl "claude-cli" };
  { name = "claude-api";  stream = not_impl "claude-api" };
  { name = "openai";      stream = not_impl "openai" };
  { name = "custom";      stream = not_impl "custom" };
]

let lookup name = List.find_opt (fun e -> e.name = name) all
