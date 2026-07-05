#!/bin/bash
set -eu

CONFIG_ROOT="/home/vpnuser/UniVPN"
CONFIG_DIR="${CONFIG_ROOT}/config"
SYSCONFIG="${CONFIG_ROOT}/sysconfig.ini"

require_env() {
  local name=$1
  if [ -z "${!name:-}" ]; then
    echo "[entrypoint] ERROR: ${name} is required" >&2
    exit 1
  fi
}

require_env VPN_GATEWAY_ADDRESS
require_env VPN_GATEWAY_PORT

PROFILE_FILE="default.ini"

mkdir -p "${CONFIG_DIR}"

cat > "${SYSCONFIG}" <<EOF
[GLOBAL]
ClientName = UniVPN
ClientVersion = 10781.19.0.1214
ClientCustomized = false
ClientLogLevel = 1

[ADVANCED]
ClientDetectLatestVersion = 1
ClientAutoBoot = 0
ClientLanguageID = 1000
ClientServerCheck = 1
ClientShowLogFlag = 0
ClientLastAccessSession = ${PROFILE_FILE}
ClientSwitchNetwork = 0
ClientTcpBufferSize = 0
ClientMtuValue = 1300

ClientReConnectTimeValue = 5
[PROXY]
ProxyType = 0
ProxyAddr = 
ProxyPort = 0
ProxyUser = 
ProxyInfo = 

[Session0]
ConnectType = 1
RemPwd = 0
AuthType = 0
AutoLogin = 0
LastLoginAddr = ${VPN_GATEWAY_ADDRESS}:${VPN_GATEWAY_PORT}
ProfileName = ${PROFILE_FILE}
ProfileUser = 
ProfileInfo = 
EOF

cat > "${CONFIG_DIR}/${PROFILE_FILE}" <<EOF
[GLOBAL]
sign_certificate = 
encryp_certificate = 
iConnectionType = 1
Description = 
GatewayAddress = ${VPN_GATEWAY_ADDRESS}
GatewayPort = ${VPN_GATEWAY_PORT}
TunnelMode = 2
PreflinkEnable = 0
DefaultGateway = -1
iroutecoverEnable = 1
icertificateEnable = 0
igmalgorithmEnable = 0
PreflinkTotal = 0
EOF

chown -R vpnuser:vpnuser "${CONFIG_ROOT}"

echo "[entrypoint] Generated UniVPN profile ${PROFILE_FILE} -> ${VPN_GATEWAY_ADDRESS}:${VPN_GATEWAY_PORT}"
exec "$@"
