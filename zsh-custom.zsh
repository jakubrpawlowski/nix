ado-ticket() {
  az boards work-item show --id "$1" --query "{Title: fields.\"System.Title\", State: fields.\"System.State\", CreatedBy: fields.\"System.CreatedBy\".displayName}" -o yaml
  echo "---"
  az boards work-item show --id "$1" --query "fields.\"System.Description\"" -o tsv | pandoc -f html -t plain --wrap=auto
}

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
