#!/bin/sh

. .env

GAS_PRICE=`cast gas-price --rpc-url $MAINNET_RPC_URL`
GAS_PRICE=`cast --to-unit $GAS_PRICE gwei`
echo "Gas Price: $GAS_PRICE"

DEPLOY_ARGS=(
    --interactive
    --rpc-url 
    $MAINNET_RPC_URL
    --json
)


P2P_VAULT=`forge create \
    ${DEPLOY_ARGS[@]} \
    src/vaults/P2PVault.sol:P2PVault | jq -r .deployedTo`

echo "P2PVault: $P2P_VAULT"

P2P_VAULT_FACTORY=`forge create src/vaults/P2PVaultFactory.sol:P2PVaultFactory \
    ${DEPLOY_ARGS[@]} \
    --constructor-args $P2P_VAULT | jq -r .deployedTo`

echo "P2PVaultFactory: $P2P_VAULT_FACTORY"

VERIFY_ARGS=(
)

forge verify-contract $P2P_VAULT src/vaults/P2PVault.sol:P2PVault ${VERIFY_ARGS[@]} 

CTOR_ARGS=`cast abi-encode "constructor(address impl_)" $P2P_VAULT`

forge verify-contract $P2P_VAULT_FACTORY src/vaults/P2PVaultFactory.sol:P2PVaultFactory \
    --constructor-args $CTOR_ARGS \
    ${VERIFY_ARGS[@]}
