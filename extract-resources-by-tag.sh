#!/bin/bash
set -euo pipefail

if [[ -z "${TAG_KEY:-}" || -z "${TAG_VALUE:-}" ]]; then
    echo "ERROR: TAG_KEY and TAG_VALUE environment variables are required but not set." >&2
    echo "Usage: TAG_KEY=mykey TAG_VALUE=myvalue $0" >&2
    exit 1
fi

export TOKEN=$(curl -sS -X POST "$SOURCE_CLUSTER/token" -H 'Content-Type: application/json' -d "{ \"keyId\": \"$SOURCE_KEY_ID\", \"keySecret\": \"$SOURCE_SECRET\" }" | jq -r .token)

if [[ "$TOKEN" == "null" || -z "$TOKEN" ]]; then
    echo "ERROR: Authentication failed. Invalid token received." >&2
    echo "Please check your SOURCE_CLUSTER, SOURCE_KEY_ID, and SOURCE_SECRET environment variables." >&2
    exit 1
fi

echo "Extracting resources for tag $TAG_KEY:$TAG_VALUE"

extract_resources() {
    local endpoint="$1"
    local resource_type="$2"

    echo "Extracting ${resource_type}s.."
    mkdir -p "$resource_type"

    if [[ "$resource_type" == "workflow" || "$resource_type" == "task" ]]; then
        local url="$SOURCE_CLUSTER/$endpoint?tagKey=$TAG_KEY&tagValue=$TAG_VALUE&metadata=true"
        curl -sS "$url" -H "X-Authorization: $TOKEN" | jq -c '.[]' | while read -r resource; do
            name=$(echo "$resource" | jq -r '.name')
            echo "$resource" | jq '.' > "$resource_type/${name}.json"
            echo "Saved $resource_type: $resource_type/${name}.json"
        done
    else
        curl -sS "$SOURCE_CLUSTER/$endpoint" -H "X-Authorization: $TOKEN" | jq -c --arg tagKey "$TAG_KEY" --arg tagValue "$TAG_VALUE" '.[] | select(.tags // [] | map(select(.key == $tagKey and .value == $tagValue)) | length > 0)' | while read -r resource; do
            name=$(echo "$resource" | jq -r '.name')
            echo "$resource" | jq '.' > "$resource_type/${name}.json"
            echo "Saved $resource_type: $resource_type/${name}.json"
        done
    fi

    echo "Finished extracting ${resource_type}s"
}

extract_resources "metadata/workflow" "workflow"
extract_resources "metadata/taskdefs" "task"
extract_resources "human/template" "user-form"
extract_resources "metadata/webhook" "webhook"
extract_resources "scheduler/schedules" "scheduler"
extract_resources "prompts" "ai-prompt"
extract_resources "event" "event-handler"

echo "Resource extraction completed"
