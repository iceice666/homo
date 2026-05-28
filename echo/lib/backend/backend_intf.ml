module type S = sig
  type t
  (** Opaque backend handle — created once at startup. *)

  type config
  (** Provider-specific configuration. *)

  val of_config : config -> (t, string) result
  (** Validate config and return a live handle, or an error string. *)

  val stream_message
    :  t
    -> history:Message.t list
    -> user_msg:string
    -> (string -> unit)
    -> (unit, string) result Lwt.t
  (** Send history + new user message. Call [on_token] for each streamed chunk. *)
end
