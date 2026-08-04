explain() {
  local cmd=""
  local line
  if [ ! -t 0 ]; then
    echo "Explaining..." >&2
    cmd=$(cat)
  else
    echo "command (hit Enter twice when done):"
    while IFS= read -r line; do
      [ -z "$line" ] && break
      cmd="${cmd:+$cmd
}$line"
    done
    echo "Explaining..."
  fi

  local output
  output=$(echo -n "$cmd" | pi --model turbofieldfare/gemma-4-26b-a4b-it -nc --no-extensions -nt -p \
    "You are a shell expert. Given a command, output four things:
1. READONLY or MUTATION depending on whether the command modifies files, deletes data, or changes system state.
2. ONE sentence describing what the command does overall.
3. EVERY flag and option THAT APPEARS IN THE COMMAND, each on its own line, with a short accurate description. Do NOT list flags that are not present.
4. CANONICAL: the command with all user-supplied values replaced by ARG1, ARG2, etc. This includes: file paths, patterns, strings, numbers, hostnames. Keep all flags, operators (|, &&, ;), subcommands, and special characters unchanged.

Output format:
READONLY or MUTATION
<one-line description>
  -x   what -x does
  --opt   what --opt does
CANONICAL: <command with ARG placeholders>

Examples:
  grep -rn 'hello' ./src
READONLY
Searches for 'hello' recursively, showing line numbers.
  -r   search subdirectories
  -n   prefix matches with line numbers
CANONICAL: grep -rn ARG1 ARG2

  find . -name '*.log' -mtime +7 -delete
MUTATION
Finds and deletes .log files older than 7 days.
  -name   filter by filename pattern
  -mtime  filter by modification time
  -delete  remove matching files
CANONICAL: find ARG1 -name ARG2 -mtime +7 -delete")

  if [[ "$output" == MUTATION* ]]; then
    print -P "%F{red}MUTATION%f"
    echo "$output" | tail -n +2
  elif [[ "$output" == READONLY* ]]; then
    print -P "%F{green}READONLY%f"
    echo "$output" | tail -n +2
  else
    echo "$output"
  fi
}
