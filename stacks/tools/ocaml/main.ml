let () =
  let name = if Array.length Sys.argv > 1 then Sys.argv.(1) else "World" in
  print_endline (Utils.greet name)


