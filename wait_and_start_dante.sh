#!/bin/bash
set -u

INTERFACE="cnem_vnic"
CHECK_INTERVAL=5

wait_for_interface() {
  echo "[Wrapper] Waiting for interface ${INTERFACE} to appear..."

  while ! ip link show "${INTERFACE}" > /dev/null 2>&1; do
    echo "[Wrapper] Interface ${INTERFACE} not found yet, waiting ${CHECK_INTERVAL}s..."
    sleep "${CHECK_INTERVAL}"
  done
}

stop_dante() {
  local pid=$1
  if kill -0 "${pid}" 2>/dev/null; then
    echo "[Wrapper] Stopping Dante server because ${INTERFACE} is unavailable..."
    kill "${pid}" 2>/dev/null || true
    wait "${pid}" 2>/dev/null || true
  fi
}

while true; do
  wait_for_interface

  echo "[Wrapper] Interface ${INTERFACE} found. Starting Dante server..."
  /usr/sbin/danted -f /etc/danted.conf &
  DANTE_PID=$!

  while kill -0 "${DANTE_PID}" 2>/dev/null; do
    if ! ip link show "${INTERFACE}" > /dev/null 2>&1; then
      stop_dante "${DANTE_PID}"
      break
    fi
    sleep "${CHECK_INTERVAL}"
  done

  echo "[Wrapper] Dante server stopped. Restarting when ${INTERFACE} is available..."
  sleep "${CHECK_INTERVAL}"
done
