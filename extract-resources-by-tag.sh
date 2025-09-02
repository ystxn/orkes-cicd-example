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

get_endpoint() {
    case "$1" in
        "workflow") echo "metadata/workflow" ;;
        "task") echo "metadata/taskdefs" ;;
        "user-form") echo "human/template" ;;
        "webhook") echo "metadata/webhook" ;;
        "scheduler") echo "scheduler/schedules" ;;
        "ai-prompt") echo "prompts" ;;
        "event-handler") echo "event" ;;
    esac
}

extract_resources() {
    local resource_type="$1"
    endpoint=$(get_endpoint "$resource_type")

    echo "Extracting ${resource_type}s.."
    mkdir -p "$resource_type" # Create directory structure if it doesn't already exist

    if [[ "$resource_type" == "workflow" || "$resource_type" == "task" ]]; then
        # Workflows and tasks support server-side filtering for tagged resources
        local url="$SOURCE_CLUSTER/$endpoint?tagKey=$TAG_KEY&tagValue=$TAG_VALUE&metadata=true"
        curl -sS "$url" -H "X-Authorization: $TOKEN" | jq -c '.[]' | while read -r resource; do
            name=$(echo "$resource" | jq -r '.name')
            echo "$resource" | jq '.' > "$resource_type/${name}.json"
            echo "Saved $resource_type: $resource_type/${name}.json"
        done
    else
        # Other resource types need to use client-side filtering
        curl -sS "$SOURCE_CLUSTER/$endpoint" -H "X-Authorization: $TOKEN" | jq -c --arg tagKey "$TAG_KEY" --arg tagValue "$TAG_VALUE" '.[] | select(.tags // [] | map(select(.key == $tagKey and .value == $tagValue)) | length > 0)' | while read -r resource; do
            name=$(echo "$resource" | jq -r '.name')
            echo "$resource" | jq '.' > "$resource_type/${name}.json"
            echo "Saved $resource_type: $resource_type/${name}.json"
        done
    fi

    echo "Finished extracting ${resource_type}s"
}

resource_types=(workflow task "user-form" webhook scheduler "ai-prompt" "event-handler")
for rt in "${resource_types[@]}"; do extract_resources "$rt"; done

echo "Resource extraction completed"
