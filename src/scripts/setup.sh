#!/bin/bash

set -eu -o pipefail

# Check if environment variables are set
missing=0

# Resolve indirect values (PARAM_* contains the variable name to read)
resolved_ngrok_api_token="${!PARAM_NGROK_API_TOKEN:-}"
resolved_ip_policy_id="${!PARAM_IP_POLICY_ID:-}"
resolved_tunnel_address="${!PARAM_TUNNEL_ADDRESS:-}"
resolved_tunnel_port="${!PARAM_TUNNEL_PORT:-}"

# Validate resolved values are non-empty
if [ -z "${resolved_ngrok_api_token}" ]; then
  echo "Error: ${PARAM_NGROK_API_TOKEN} is not set or empty"
  missing=1
fi
if [ -z "${resolved_ip_policy_id}" ]; then
  echo "Error: ${PARAM_IP_POLICY_ID} is not set or empty"
  missing=1
fi
if [ -z "${resolved_tunnel_address}" ]; then
  echo "Error: ${PARAM_TUNNEL_ADDRESS} is not set or empty"
  missing=1
fi
if [ -z "${resolved_tunnel_port}" ]; then
  echo "Error: ${PARAM_TUNNEL_PORT} is not set or empty"
  missing=1
fi
if [ "$missing" -ne 0 ]; then
  exit 1
fi

tunnel_file="$(mktemp)"
ip="$(curl --fail https://checkip.amazonaws.com/)"

echo "Setting up the CircleCI tunnel with IP: $ip"

if [[ -n "${DEBUG:-}" ]]; then
  echo "DEBUG curl command:"
  echo curl -H 'Accept: application/json' \
    -H "Authorization: Bearer ${resolved_ngrok_api_token}" \
    -H "Content-Type: application/json" \
    -H "Ngrok-Version: 2" \
    -d '{"action":"allow","cidr":"'"${ip}"'/32","description":"'"$CIRCLE_BUILD_URL"'","ip_policy_id":"'"${resolved_ip_policy_id}"'"}' \
    --fail -o "$tunnel_file" \
    "https://api.ngrok.com/ip_policy_rules"
fi

curl -H 'Accept: application/json' \
  -H "Authorization: Bearer ${resolved_ngrok_api_token}" \
  -H "Content-Type: application/json" \
  -H "Ngrok-Version: 2" \
  -d '{"action":"allow","cidr":"'"${ip}"'/32","description":"'"$CIRCLE_BUILD_URL"'","ip_policy_id":"'"${resolved_ip_policy_id}"'"}' \
  --fail -o "$tunnel_file" \
  "https://api.ngrok.com/ip_policy_rules"

echo "Exporting IPR_ID to environment"
echo "export IPR_ID=\"$(jq -r '.id' "$tunnel_file")\"" >> "$BASH_ENV"
echo "Sourcing BASH_ENV to update the environment"
# shellcheck source=/dev/null
source "$BASH_ENV"

if [[ -n "${DEBUG:-}" ]]; then
  echo "DEBUG IPR_ID: ${IPR_ID}"
fi

echo "The CircleCI tunnel setup is complete"
