#!/bin/sh
NETWORK="localhost"
RPC_URL="http://localhost:8545"
CHAIN_ID="1337"

DEPLOYER=0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
DEPLOYER_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

ALICE=0x70997970c51812dc3a010c7d01b50e0d17dc79c8
ALICE_PK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

BOB=0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc
BOB_PK=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

CHARLES=0x90f79bf6eb2c4f870365e785982e1f101e93b906
CHARLES_PK=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6

DEPLOY_ARGS=(
    --unlocked 
    --from 
    $DEPLOYER
    --rpc-url 
    http://localhost:8545
    --json
)

export ETHERSCAN_API_KEY=blacksmith
VERIFY_ARGS=(
    --verifier-url 
    http://localhost:3000/api/verify
)


MOCK_ERC20=`forge create test/mocks/MockERC20.sol:MockERC20 --constructor-args "TOKEN A" "TOKENA" ${DEPLOY_ARGS[@]} | jq -r .deployedTo`
# forge verify-contract $MOCK_ERC20 test/mocks/MockERC20.sol:MockERC20 --constructor-args "TOKEN A" "TOKENA" ${VERIFY_ARGS[@]} 

P2P_VAULT=`forge create src/vaults/P2PVault.sol:P2PVault ${DEPLOY_ARGS[@]} | jq -r .deployedTo`
# forge verify-contract $P2P_VAULT src/vaults/P2PVault.sol:P2PVault ${VERIFY_ARGS[@]} 

P2P_VAULT_FACTORY=`forge create src/vaults/P2PVaultFactory.sol:P2PVaultFactory --constructor-args $P2P_VAULT ${DEPLOY_ARGS[@]} | jq -r .deployedTo`
# forge verify-contract $P2P_VAULT_FACTORY src/vaults/P2PVaultFactory.sol:P2PVaultFactory ${VERIFY_ARGS[@]} 

cast send --private-key $DEPLOYER_PK \
	$MOCKERC20 \
	"mint(address,uint256)" $ALICE \
	0x00000000000000000000000000000000000000000000021e19e0c9bab2400000 >/dev/null

cast send --private-key $DEPLOYER_PK \
	$MOCKERC20 \
	"mint(address,uint256)" $BOB \
	0x00000000000000000000000000000000000000000000021e19e0c9bab2400000 >/dev/null

cast send --private-key $DEPLOYER_PK \
	$MOCKERC20 \
	"mint(address,uint256)" $CHARLES \
	0x00000000000000000000000000000000000000000000021e19e0c9bab2400000 >/dev/null

echo "P2P_VAULT_FACTORY=$P2P_VAULT_FACTORY"