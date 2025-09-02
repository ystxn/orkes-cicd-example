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
        "workflow") echo "metadata/workflow?overwrite=true" ;;
        "task") echo "metadata/taskdefs" ;;
        "user-form") echo "human/template" ;;
        "webhook") echo "metadata/webhook" ;;
        "scheduler") echo "scheduler/schedules" ;;
        "ai-prompt") echo "prompts/" ;;
        "event-handler") echo "event" ;;
    esac
}

process_file() {
    local file_path="$1"
    local resource_type=$(dirname "$file_path" | cut -d'/' -f1)
    local endpoint=$(get_endpoint "$resource_type")

    echo "Deploying $file_path"

    local json_content=$(cat "$file_path")
    if [[ "$resource_type" == "ai-prompt" ]]; then
        json_content="[$json_content]"
    fi

    local response_code=$(curl -sS -w "%{http_code}" -X POST -H "Content-Type: application/json" -H "X-Authorization: $TOKEN" -d "$json_content" "$TARGET_CLUSTER/$endpoint")

    if [[ "$response_code" =~ ^20[0,1]$ ]]; then
        echo "Successfully deployed $file_path"
        return 0
    else
        echo "ERROR: Failed to deploy $file_path (HTTP $response_code)" >&2
        return 1
    fi
}

success_count=0
error_count=0

while IFS= read -r file; do
    if [[ -n "$file" ]]; then
        if process_file "$file"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    fi
done <<< "$1"

echo "Processing complete: $success_count successful, $error_count failed"

if [[ $error_count -gt 0 ]]; then
    exit 1
fi
