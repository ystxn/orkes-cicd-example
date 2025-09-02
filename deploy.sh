#!/bin/bash
set -euo pipefail

export TOKEN=$(curl -sS -X POST "$TARGET_CLUSTER/token" -H 'Content-Type: application/json' -d "{ \"keyId\": \"$TARGET_KEY_ID\", \"keySecret\": \"$TARGET_SECRET\" }" | jq -r .token)

if [[ "$TOKEN" == "null" || -z "$TOKEN" ]]; then
    echo "ERROR: Authentication failed. Invalid token received." >&2
    echo "ERROR: Please check your TARGET_CLUSTER, TARGET_KEY_ID, and TARGET_SECRET environment variables." >&2
    exit 1
fi

get_endpoint() {
    case "$1" in
        "workflow") echo "metadata/workflow" ;;
        "task") echo "metadata/taskdefs" ;;
        "user-form") echo "human/template" ;;
        "webhook") echo "metadata/webhook" ;;
        "scheduler") echo "scheduler/schedules" ;;
        "ai-prompt") echo "prompts/" ;;
        "event-handler") echo "event" ;;
    esac
}

post_only_resources=("user-form" "scheduler" "ai-prompt")

process_file() {
    resource_type=$(dirname "$file_path" | cut -d'/' -f1)
    endpoint=$(get_endpoint "$resource_type")
    http_method="POST"; [[ "$status" == "M" && ! " ${post_only_resources[*]} " =~ " ${resource_type} " ]] && http_method="PUT"

    if [[ "$resource_type" == "webhook" && "$status" == "M" ]]; then
        webhook_id=$(jq -r '.id' "$file_path")
        endpoint="${endpoint}/${webhook_id}"
    fi

    action="Deploying"; [[ "$status" == "M" ]] && action="Updating"
    echo "$action: $file_path"

    if [[ "$resource_type" == "ai-prompt" ]] || [[ "$resource_type" == "workflow" && "$status" == "M" ]]; then
        printf '[%s]\n' "$(cat $file_path)" > "$file_path.tmp" && file_path="$file_path.tmp"
    fi

    out="$(curl -s --fail-with-body -H "Content-Type: application/json" -H "X-Authorization: $TOKEN" -X "$http_method" -d @"$file_path" "$TARGET_CLUSTER/$endpoint" -w "\nHTTP %{http_code}")" \
        && echo "Success" || { echo "Error: $file_path (${out##*$'\n'})" >&2; echo "${out%$'\n'*}"|jq; return 1; }
}

success_count=0
error_count=0

while IFS= read -r line; do
    read -r status file_path <<< "$line"
    process_file && success_count=$((success_count + 1)) || error_count=$((error_count + 1))
done <<< "$files"

echo "Processing complete: $success_count successful, $error_count failed"

[[ $error_count -gt 0 ]] && exit 1 || true
