# ABI reference

Generated from the successfully compiled primary contract. Includes inherited OpenZeppelin methods. Authorization requirements and economic semantics are in the Solidity source and architecture guide.

| Signature | Type | Mutability | Return values |
|---|---|---|---|
| `constructor(address asset,uint64 delay,address admin)` | constructor | nonpayable |  |
| `EnforcedPause()` | error |  |  |
| `ExpectedPause()` | error |  |  |
| `OwnableInvalidOwner(address owner)` | error |  |  |
| `OwnableUnauthorizedAccount(address account)` | error |  |  |
| `ReentrancyGuardReentrantCall()` | error |  |  |
| `SafeERC20FailedOperation(address token)` | error |  |  |
| `Cancelled(uint256 batch)` | event |  |  |
| `OwnershipTransferStarted(address previousOwner,address newOwner)` | event |  |  |
| `OwnershipTransferred(address previousOwner,address newOwner)` | event |  |  |
| `Paused(address account)` | event |  |  |
| `Published(uint256 batch,bytes32 root,uint256 amount,uint64 activateAt)` | event |  |  |
| `Released(uint256 batch,bytes32 message,address recipient,uint256 amount)` | event |  |  |
| `Unpaused(address account)` | event |  |  |
| `acceptOwnership()` | function | nonpayable |  |
| `batches(uint256 )` | function | view | bytes32 root, uint256 remaining, uint64 activateAt, bool cancelled |
| `cancel(uint256 batch)` | function | nonpayable |  |
| `challengeDelay()` | function | view | uint64  |
| `consumed(bytes32 )` | function | view | bool  |
| `liability()` | function | view | uint256  |
| `messageLeaf(uint256 batch,bytes32 message,address recipient,uint256 amount)` | function | view | bytes32  |
| `owner()` | function | view | address  |
| `paused()` | function | view | bool  |
| `pendingOwner()` | function | view | address  |
| `publish(uint256 batch,bytes32 root,uint256 amount)` | function | nonpayable |  |
| `release(uint256 batch,bytes32 message,address recipient,uint256 amount,bytes32[] proof)` | function | nonpayable |  |
| `renounceOwnership()` | function | nonpayable |  |
| `setPaused(bool value)` | function | nonpayable |  |
| `token()` | function | view | address  |
| `transferOwnership(address newOwner)` | function | nonpayable |  |
