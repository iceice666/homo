type role = [ `User | `Assistant | `System ]

type t = {
  role : role;
  content : string;
}

let make role content = { role; content }
