#!/usr/bin/env bash

IFACE="${AWG_INTERFACE:-awg0}"
CONF="/etc/amnezia/amneziawg/${IFACE}.conf"
CLEAN_CONF="/tmp/${IFACE}.conf"

if [[ ! -f "$CONF" ]]; then
  echo "ERROR: config not found at $CONF"
  exit 1
fi

# Extract - handle spaces around = and any casing
ADDRESS=$(grep -m1 -i '^\s*Address\s*=' "$CONF" | sed 's/.*=\s*//' | tr -d ' \r\n')
DNS=$(grep -m1 -i '^\s*DNS\s*=' "$CONF" | sed 's/.*=\s*//' | tr -d ' \r\n')

# Strip all fields that awg setconf doesn't understand
sed 's/\r//' "$CONF" \
  | grep -v -iE '^\s*(Address|DNS|MTU|Table|PreUp|PostUp|PreDown|PostDown|S3|S4|I1|I2|I3|I4|I5)\s*=' \
  > "$CLEAN_CONF"

# Clean up any leftover interface
if ip link show "${IFACE}" &>/dev/null; then
  ip link delete "${IFACE}" 2>/dev/null || true
fi

# Start userspace daemon
amneziawg-go "${IFACE}"
sleep 1

# Apply config
awg setconf "${IFACE}" "$CLEAN_CONF"

# Bring interface up
ip addr add "$ADDRESS" dev "${IFACE}"
ip link set mtu 1420 up dev "${IFACE}"

# Set DNS directly
if [[ -n "$DNS" ]]; then
  {
    for ns in ${DNS//,/ }; do
      echo "nameserver $(echo "$ns" | tr -d ' ')"
    done
  } > /etc/resolv.conf
  echo ">>> DNS set to: $DNS"
fi

# Routing
awg set "${IFACE}" fwmark 51820
ip rule add not fwmark 51820 table 51820 2>/dev/null || true
ip rule add table main suppress_prefixlength 0 2>/dev/null || true
ip route add 0.0.0.0/0 dev "${IFACE}" table 51820 2>/dev/null || true

trap "ip link delete ${IFACE} 2>/dev/null; exit 0" SIGTERM SIGINT
sleep infinity