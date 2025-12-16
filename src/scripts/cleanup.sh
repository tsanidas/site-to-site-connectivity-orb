#!/bin/bash

set -eu -o pipefail

# Check if environment variables are set
missing=0

# Resolve indirect values (PARAM_* contains the variable name to read)
resolved_ngrok_api_token="${!PARAM_NGROK_API_TOKEN:-}"

if [ -z "${resolved_ngrok_api_token}" ]; then
  echo "Error: ${PARAM_NGROK_API_TOKEN} is not set or empty"
  missing=1
fi
if [ -z "${IPR_ID:-}" ]; then
  echo "Error: IPR_ID is not set or empty"
  missing=1
fi
if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "Cleaning up CircleCI tunnel with IPR_ID: ${IPR_ID}"

if [[ -n "${DEBUG:-}" ]]; then
  echo "DEBUG curl command:"
  echo curl -H 'Accept: application/json' \
    -H "Authorization: Bearer ${resolved_ngrok_api_token}" \
    -H "Content-Type: application/json" \
    -H "Ngrok-Version: 2" \
    -X DELETE \
    --fail \
    "https://api.ngrok.com/ip_policy_rules/${IPR_ID}"
fi

curl -H 'Accept: application/json' \
  -H "Authorization: Bearer ${resolved_ngrok_api_token}" \
  -H "Content-Type: application/json" \
  -H "Ngrok-Version: 2" \
  -X DELETE \
  --fail \
  "https://api.ngrok.com/ip_policy_rules/${IPR_ID}"

echo "CircleCI tunnel cleanup complete"
