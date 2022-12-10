#!/bin/sh

. .env

#P2P_VAULT=`forge create --rpc-url $MAINNET_RPC_URL \
#    --from $MAINNET_DEPLOYER \
#    --ledger \
#    --verify \
#    --etherscan-api-key $ETHERSCAN_API_KEY \
#    --json \
#    src/vaults/P2PVault.sol:P2PVault | jq -r .deployedTo`

P2P_VAULT=0x3774d3f504ff31f442765e1c4c89794D9c0Bd962

echo "P2PVault: $P2P_VAULT"


forge create src/vaults/P2PVaultFactory.sol:P2PVaultFactory \
    --rpc-url $MAINNET_RPC_URL \
    --from $MAINNET_DEPLOYER \
    --ledger \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $P2P_VAULT 

