#!/usr/bin/env bash

if [ -z "${TAILNET_ID}" ]; then
  echo "Env TAILNET_ID is not set!"
  echo "Open https://login.tailscale.com/admin/settings/general to get this value"
  exit 1
fi

if [ -z "${TS_CLIENT_ID}" ]; then
  echo "Env TS_CLIENT_ID is not set!"
  exit 1
fi

if [ -z "${TS_CLIENT_SECRET}" ]; then
  echo "Env TS_CLIENT_SECRET is not set!"
  exit 1
fi

TOKEN=$(curl -s -d "client_id=${TS_CLIENT_ID}" -d "client_secret=${TS_CLIENT_SECRET}" "https://api.tailscale.com/api/v2/oauth/token" | jq -r '.access_token')

if [ -n "${CLEANUP_HOSTNAME}" ]; then
  IDS=$(curl -s "https://api.tailscale.com/api/v2/tailnet/$TAILNET_ID/devices" -H "Authorization: Bearer ${TOKEN}" | jq -r ".devices[] | select(.hostname | contains(\"$CLEANUP_HOSTNAME\")) | .nodeId")
else
  IDS=$(curl -s "https://api.tailscale.com/api/v2/tailnet/$TAILNET_ID/devices" -H "Authorization: Bearer ${TOKEN}" | jq -r ".devices[] | select(.tags[]? | contains(\"${CLEANUP_TAG:-k8s}\")) | select(.connectedToControl == false) | .nodeId")
fi

for ID in ${IDS}; do
  echo "Deleting device ${ID}";
  curl -s -X DELETE "https://api.tailscale.com/api/v2/device/${ID}" -H "Authorization: Bearer ${TOKEN}"
done

# tailscale does not support persistent hostnames, this is our workaround to rename the number appended hostnames back to our desired name
ITEMS=$(curl -s "https://api.tailscale.com/api/v2/tailnet/$TAILNET_ID/devices" -H "Authorization: Bearer ${TOKEN}" | jq -r ".devices[] | select(.tags[]? | contains(\"${CLEANUP_TAG:-k8s}\")) | select(.connectedToControl == true) | select(.name | test(\"-[0-9]+\")) | [.nodeId, .hostname] | @tsv")

if [ -n "$ITEMS" ]; then
  echo "$ITEMS" | while IFS=$'\t' read -r nodeId name; do
    echo "Fix name for $nodeId : $name"
    curl -s "https://api.tailscale.com/api/v2/device/$nodeId/name" \
      --request POST \
      --header "Content-Type: application/json" \
      --header "Authorization: Bearer $TOKEN" \
      --data "{ \"name\": \"$name\" }"
  done
fi

sleep 1
