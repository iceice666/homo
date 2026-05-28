let version = "0.1.0"

let usage () =
  print_string
    {|echo — personal conversational AI companion

USAGE:
    echo chat [--backend <name>] [--profile <name>]
    echo sessions list
    echo sessions show <id>
    echo config show
    echo --version

BACKENDS:
    claude-cli   subprocess wrapper (default if `claude` is on PATH)
    claude-api   Anthropic REST API (BYOK)
    openai       OpenAI REST API (BYOK)
    custom       OpenAI-compatible endpoint (Ollama, etc.)

CONFIG: ~/.config/echo/config.toml
|}

let () =
  let argv = match Array.to_list Sys.argv with _ :: rest -> rest | [] -> [] in
  match argv with
  | [ "--version" ] | [ "-v" ] -> print_endline ("echo " ^ version)
  | [ "--help" ] | [ "-h" ] | [] -> usage ()
  | "chat" :: _ ->
    let _cfg = Echo.Config.default in
    Printf.eprintf "echo: chat not yet implemented\n";
    exit 1
  | "sessions" :: "list" :: _ ->
    Printf.eprintf "echo: sessions list not yet implemented\n";
    exit 1
  | "sessions" :: "show" :: _ ->
    Printf.eprintf "echo: sessions show not yet implemented\n";
    exit 1
  | "config" :: "show" :: _ ->
    let _cfg = Echo.Config.default in
    Printf.eprintf "echo: config show not yet implemented\n";
    exit 1
  | cmd :: _ ->
    Printf.eprintf "echo: unknown command '%s'\n" cmd;
    exit 1
