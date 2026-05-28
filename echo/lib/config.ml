type t = {
  default_backend : string option;
  default_profile : string option;
}

let default = { default_backend = None; default_profile = None }

(* Config precedence: CLI flags > ECHO_* env vars > ~/.config/echo/config.toml *)
let load _path =
  (* TODO: parse TOML via Otoml, merge env vars *)
  Ok default

let config_dir () =
  let home = Sys.getenv_opt "HOME" |> Option.value ~default:"/tmp" in
  Filename.concat home ".config/echo"

let default_path () = Filename.concat (config_dir ()) "config.toml"
