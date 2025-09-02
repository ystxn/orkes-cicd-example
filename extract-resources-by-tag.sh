#!/bin/bash
set -euo pipefail
export TOKEN=$(curl -sS -X POST "$SOURCE_CLUSTER/token" -H 'Content-Type: application/json' -d "{ \"keyId\": \"$SOURCE_KEY_ID\", \"keySecret\": \"$SOURCE_SECRET\" }" | jq -r .token)

extract_with_url_filter() {
    local endpoint="$1"
    local resource_type="$2"

    mkdir -p "$resource_type"
    curl -sS "$SOURCE_CLUSTER/$endpoint?tagKey=$1&tagValue=$2" -H "X-Authorization: $TOKEN" | jq -c '.[]' | while read -r resource; do
        name=$(echo "$resource" | jq -r '.name')
        echo "$resource" | jq '.' > "$resource_type/${name}.json"
        echo "Saved $resource_type: $resource_type/${name}.json"
    done
}

extract_with_client_filter() {
    local endpoint="$1"
    local resource_type="$2"

    mkdir -p "$resource_type"
    curl -sS "$SOURCE_CLUSTER/$endpoint" -H "X-Authorization: $TOKEN" | jq -c --arg tagKey "$1" --arg tagValue "$2" '.[] | select(.tags // [] | map(select(.key == $tagKey and .value == $tagValue)) | length > 0)' | while read -r resource; do
        name=$(echo "$resource" | jq -r '.name')
        echo "$resource" | jq '.' > "$resource_type/${name}.json"
        echo "Saved $resource_type: $resource_type/${name}.json"
    done
}

extract_with_url_filter "metadata/workflow" "workflow" &
extract_with_url_filter "metadata/taskdefs" "task" &
extract_with_client_filter "human/template" "user-form" &
extract_with_client_filter "metadata/webhook" "webhook" &
extract_with_client_filter "scheduler/schedules" "scheduler" &
extract_with_client_filter "prompts" "ai-prompt" &
extract_with_client_filter "event" "event-handler" &

wait
echo "Resource extraction completed"
