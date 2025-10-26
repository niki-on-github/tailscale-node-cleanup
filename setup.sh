#!/usr/bin/env bash

if [ -z "${TAILNET_ID}" ]; then
  echo "Env TAILNET_ID is not set!"
  echo "Open https://login.tailscale.com/admin/settings/general to get this value"
  exit 1
fi

if [ -z "${NODE_NAME}" ]; then
  echo "Env NODE_NAME is not set!"
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
IDS=$(curl -s "https://api.tailscale.com/api/v2/tailnet/$TAILNET_ID/devices" -H "Authorization: Bearer ${TOKEN}" | jq -r ".devices[] | select(.hostname | contains(\"$NODE_NAME\")) | .nodeId")
for ID in ${IDS}; do
  echo "Deleting device ${ID}";
  curl -s -X DELETE "https://api.tailscale.com/api/v2/device/${ID}" -H "Authorization: Bearer ${TOKEN}"
done

sleep 5
