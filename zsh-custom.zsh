explain() {
  local cmd=""
  local line
  if [ ! -t 0 ]; then
    print -u2 "Explaining..."
    cmd=$(cat)
  else
    print "command (hit Enter twice when done):"
    while IFS= read -r line; do
      [ -z "$line" ] && break
      cmd="${cmd:+$cmd
}$line"
    done
    print "Explaining..."
  fi

  echo -n "$cmd" | pi -nc --no-extensions -nt -p \
    "Break down this shell command. Explain what the command does and what each flag/argument means. Be concise. On the LAST line, print 'CANONICAL:' followed by the command with all positional arguments replaced by ARG1, ARG2, etc. Keep all flags, subcommands, and operators (|, >, &&, ;)."
}
