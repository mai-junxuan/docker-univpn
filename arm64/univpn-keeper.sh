#!/bin/bash
set -u

APP_DIR=${UNIVPN_APP_DIR:-/opt/apps/cn.com.huawei-security-commercial-alliance.univpn/files}
APP_CMD="${APP_DIR}/serviceclient/UniVPNCS"
TARGET=${VPN_GATEWAY_ADDRESS:?VPN_GATEWAY_ADDRESS is required}
ENABLE=true
GRACE=60
CHECK_INTERVAL=${HEALTH_CHECK_INTERVAL:-10}
RETRY_DELAY=${RETRY_DELAY:-5}
VPN_USERNAME=${VPN_USERNAME:-}
VPN_PASSWORD=${VPN_PASSWORD:-}
DEBUG_MODE=${DEBUG_MODE:-false}

log() {
  echo "[Keeper $(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

if [ -z "$VPN_USERNAME" ]; then
  log "ERROR: VPN_USERNAME is not set"
  exit 1
fi

if [ -z "$VPN_PASSWORD" ]; then
  log "ERROR: VPN_PASSWORD is not set"
  exit 1
fi

check_connectivity() {
  ping -c 1 -W 2 "$TARGET" >/dev/null 2>&1
}

ensure_stopped() {
  local pid=$1
  if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
    log "Stopping VPN process (PID: $pid)..."
    kill "$pid" 2>/dev/null || true

    local count=0
    while kill -0 "$pid" 2>/dev/null; do
      if [ "$count" -ge 20 ]; then
        log "Process stuck. Force killing (SIGKILL)..."
        kill -9 "$pid" 2>/dev/null || true
        break
      fi
      sleep 1
      count=$((count + 1))
    done
  fi
}

start_vpn() {
  cd "$APP_DIR"

  local expect_debug=""
  if [ "$DEBUG_MODE" = "true" ]; then
    expect_debug='exp_internal 1'
  fi

  VPN_USERNAME="$VPN_USERNAME" VPN_PASSWORD="$VPN_PASSWORD" APP_CMD="$APP_CMD" expect -c "
set timeout 45
log_user 1
${expect_debug}

spawn \$env(APP_CMD)

expect {
  -re {<Connection Name List>} {
    exp_continue
  }
  -re {3:} {
    send \"3\r\"
  }
  timeout {
    puts \"\\[Keeper\\] Timeout waiting for connection list\"
    exit 1
  }
  eof {
    puts \"\\[Keeper\\] UniVPNCS exited before connection list\"
    exit 1
  }
}

expect {
  -re {1:Connect} {
    send \"1\r\"
  }
  timeout {
    puts \"\\[Keeper\\] Timeout waiting for profile menu\"
    exit 1
  }
}

expect {
  -re {login user name} {
    send \"\$env(VPN_USERNAME)\r\"
    exp_continue
  }
  -re {login user password} {
    send \"\$env(VPN_PASSWORD)\r\"
    exp_continue
  }
  -re {Successful login} {
    exp_continue
  }
  -re {Succeeded in enabling network extension} {
    exp_continue
  }
  -re {(Authentication failed|login failed|Connection Failed|failed)} {
    puts \"\\[Keeper\\] Authentication or connection failed\"
    exit 1
  }
  -re {Connect Success,Enjoy} {
    puts \"\\[Keeper\\] VPN connected\"
  }
  timeout {
    puts \"\\[Keeper\\] Timeout waiting for login result\"
    exit 1
  }
  eof {
    puts \"\\[Keeper\\] UniVPNCS exited during login\"
    exit 1
  }
}

set timeout -1
expect eof
"
}

log "Cleaning up existing UniVPNCS processes..."
pkill -f "$APP_CMD" 2>/dev/null || true
sleep 2

while true; do
  log "Starting ARM64 UniVPN CLI connection..."
  start_vpn &
  VPN_PID=$!
  log "UniVPNCS expect process started with PID: $VPN_PID"

  if [ "$ENABLE" = "true" ]; then
    log "Auto-reconnect ENABLED. Target: $TARGET"
    sleep "$GRACE"

    fail_count=0
    while kill -0 "$VPN_PID" 2>/dev/null; do
      if check_connectivity; then
        fail_count=0
        sleep "$CHECK_INTERVAL"
      else
        fail_count=$((fail_count + 1))
        log "Connectivity check failed (${fail_count}/2)"
        if [ "$fail_count" -ge 2 ]; then
          break
        fi
        sleep 2
      fi
    done
  else
    wait "$VPN_PID"
    exit_code=$?
    log "UniVPNCS expect process exited with code: $exit_code"
  fi

  ensure_stopped "$VPN_PID"
  log "Restarting in ${RETRY_DELAY}s..."
  sleep "$RETRY_DELAY"
done
