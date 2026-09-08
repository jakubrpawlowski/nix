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

# edit the current command line in $EDITOR (helix), like nushell's ctrl+o
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^O' edit-command-line

# print all tuicr review comments (staged/unstaged/pristine sessions) as markdown
# usage: tuicr-get-comments [repo] | pbcopy
tuicr-get-comments() {
  local repo="${1:-.}"
  local sessions
  sessions=$(tuicr review list --repo "$repo" | jq -r '.[] | select(.comment_count > 0) | .slug')
  if [[ -z "$sessions" ]]; then
    echo "no tuicr comments found for $repo" >&2
    return 1
  fi
  local magenta="" reset="" dark_grey=""
  if [ -t 1 ]; then
    magenta=$'\033[35m'
    reset=$'\033[0m'
    dark_grey=$'\033[90m'
  fi
  local repo_path="${repo:a}"
  echo "# tuicr code review comments to address ($repo_path)"
  echo "$sessions" | while IFS= read -r s; do
    echo
    echo "## $s"
    tuicr review comments --session "$s" 2>/dev/null | jq -r --arg magenta "$magenta" --arg reset "$reset" --arg dark_grey "$dark_grey" '.[] |
      "- [ ] " +
      (if .comment_type != "none" then "[" + .comment_type + "] " else "" end) +
      $magenta + (.path // "(review)") + (if .start_line then ":" + (.start_line|tostring) else "" end) + $reset +
      " [" + (.side // "-") + "] — " + .content +
      "  " + $dark_grey + "(" + .id + ")" + $reset'
  done
}

# delete tuicr comments interactively (fzf): pick a session, multi-select comments
# close any running tuicr TUI first, or it may rewrite the session and undo deletions
tuicr-delete-comments() {
  local repo="${1:-.}"
  local sessions
  sessions=$(tuicr review list --repo "$repo" | jq -c '.[] | select(.comment_count > 0)')
  if [[ -z "$sessions" ]]; then
    echo "no tuicr comments found for $repo" >&2
    return 1
  fi
  while true; do
    local slug
    slug=$(echo "$sessions" | jq -r '"\(.slug)\t\(.comment_count) comment(s)"' | fzf --delimiter='\t' --with-nth=1 | cut -f1)
    [[ -z "$slug" ]] && return 0
    local picked
    picked=$(tuicr review comments --session "$slug" 2>/dev/null | jq -r '.[] | "\(.id)\t\(.location // "(review)")\t\(.content)"' | fzf --multi --delimiter='\t' --with-nth=2,3 --preview 'echo {} | cut -f3-' | cut -f1)
    [[ -z "$picked" ]] && continue
    while IFS= read -r id; do
      tuicr review delete --repo "$repo" --session "$slug" --comment-id "$id" >/dev/null ||
        echo "failed to delete comment $id" >&2
    done <<< "$picked"
    return 0
  done
}
