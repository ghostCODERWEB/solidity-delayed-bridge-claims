// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {SuiteBase, AssetFlow} from "./SuiteBase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Delayed bridge claim escrow
/// @notice Funded message epochs with publisher delay, cancellable pending roots and replay-protected token releases.
/// @dev Reference implementation; independent audit required before production.

contract DelayedBridgeEscrow is SuiteBase {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    uint64 public immutable challengeDelay;
    uint256 public liability;
    struct Batch {
        bytes32 root;
        uint256 remaining;
        uint64 activateAt;
        bool cancelled;
    }
    mapping(uint256 => Batch) public batches;
    mapping(bytes32 => bool) public consumed;
    event Published(
        uint256 indexed batch,
        bytes32 root,
        uint256 amount,
        uint64 activateAt
    );
    event Cancelled(uint256 indexed batch);
    event Released(
        uint256 indexed batch,
        bytes32 indexed message,
        address indexed recipient,
        uint256 amount
    );
    constructor(address asset, uint64 delay, address admin) SuiteBase(admin) {
        require(asset.code.length > 0 && delay > 0, "config");
        token = IERC20(asset);
        challengeDelay = delay;
    }
    function messageLeaf(
        uint256 batch,
        bytes32 message,
        address recipient,
        uint256 amount
    ) public view returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    keccak256(
                        abi.encode(
                            block.chainid,
                            address(this),
                            batch,
                            message,
                            recipient,
                            amount
                        )
                    )
                )
            );
    }
    function publish(
        uint256 batch,
        bytes32 root,
        uint256 amount
    ) external onlyOwner nonReentrant whenNotPaused {
        require(
            batches[batch].root == bytes32(0) && root != bytes32(0),
            "batch"
        );
        AssetFlow.pullExact(token, msg.sender, amount);
        uint64 time = uint64(block.timestamp) + challengeDelay;
        batches[batch] = Batch(root, amount, time, false);
        liability += amount;
        emit Published(batch, root, amount, time);
    }
    function cancel(uint256 batch) external onlyOwner nonReentrant {
        Batch storage b = batches[batch];
        require(
            b.root != bytes32(0) &&
                !b.cancelled &&
                block.timestamp < b.activateAt,
            "cancel"
        );
        b.cancelled = true;
        uint256 amount = b.remaining;
        b.remaining = 0;
        liability -= amount;
        token.safeTransfer(msg.sender, amount);
        emit Cancelled(batch);
    }
    function release(
        uint256 batch,
        bytes32 message,
        address recipient,
        uint256 amount,
        bytes32[] calldata proof
    ) external nonReentrant whenNotPaused {
        Batch storage b = batches[batch];
        require(
            b.root != bytes32(0) &&
                !b.cancelled &&
                block.timestamp >= b.activateAt &&
                recipient != address(0) &&
                amount > 0 &&
                !consumed[message],
            "release"
        );
        require(
            MerkleProof.verifyCalldata(
                proof,
                b.root,
                messageLeaf(batch, message, recipient, amount)
            ),
            "proof"
        );
        require(amount <= b.remaining, "budget");
        consumed[message] = true;
        b.remaining -= amount;
        liability -= amount;
        token.safeTransfer(recipient, amount);
        emit Released(batch, message, recipient, amount);
    }
}
