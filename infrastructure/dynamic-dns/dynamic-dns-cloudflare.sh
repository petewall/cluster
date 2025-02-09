set -eo pipefail

if [ -z "${DOMAIN}" ]; then
  echo "DOMAIN must be defined!"
  exit 1
fi

if [ -z "${TOKEN}" ]; then
  echo "TOKEN must be defined!"
  exit 1
fi

echo "Updating ${DOMAIN}..."

ZONE_ID=$(curl --url "https://api.cloudflare.com/client/v4/zones" \
    --header "Authorization: Bearer ${TOKEN}" \
    | jq -r '.result[] | select(.name=="petewall.net") | .id')

DNS_ID=$(curl --url "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    --header "Authorization: Bearer ${TOKEN}" \
    | jq --arg DOMAIN "${DOMAIN}" -r '.result[] | select(.name==$DOMAIN and .type=="A") | .id')

IP=$(curl icanhazip.com)

curl --request PUT \
  --url "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${DNS_ID}" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer ${TOKEN}" \
  --data '{
  "content": "'"${IP}"'",
  "name": "'"${DOMAIN}"'",
  "proxied": false,
  "type": "A",
  "ttl": 1
}'

echo "Done!"
