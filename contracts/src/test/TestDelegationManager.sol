// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IDelegationManager} from "@eigenlayer-contracts/interfaces/IDelegationManager.sol";
import {IStrategy} from "@eigenlayer-contracts/interfaces/IStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestDelegationManager is IDelegationManager {
    mapping(address => bool) public isOperator;
    mapping(address => mapping(IStrategy => uint256)) public operatorShares;
    mapping(address => mapping(bytes32 => bool)) public delegationApproverSalts;

    function registerAsOperator(OperatorDetails calldata /* registeringOperatorDetails */, string calldata /* metadataURI */) external {}

    function setIsOperator(address operator, bool _isOperatorReturnValue) external {
        isOperator[operator] = _isOperatorReturnValue;
    }

    function getOperatorShares(address operator, IStrategy[] memory strategies)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory shares = new uint256[](strategies.length);
        for (uint256 i = 0; i < strategies.length; i++) {
            shares[i] = operatorShares[operator][strategies[i]];
        }
        return shares;
    }

    function isDelegated(address /* staker */) external pure returns (bool) {
        return true;
    }

    function delegatedTo(address /* staker */) external pure returns (address) {
        return address(0);
    }

    function delegateToBySignature(
        address staker,
        address /* operator */,
        SignatureWithExpiry memory /* stakerSignatureAndExpiry */,
        SignatureWithExpiry memory /* approverSignatureAndExpiry */,
        bytes32 approverSalt
    ) external {
        delegationApproverSalts[staker][approverSalt] = true;
    }

    function delegateTo(
        address /* operator */,
        SignatureWithExpiry memory /* approverSignatureAndExpiry */,
        bytes32 approverSalt
    ) external {
        delegationApproverSalts[msg.sender][approverSalt] = true;
    }

    function undelegate(address /* staker */) external pure returns (bytes32[] memory) {
        return new bytes32[](0);
    }

    function stakerOptOutWindowBlocks(address /* operator */) external pure returns (uint256) {
        return 0;
    }

    function increaseDelegatedShares(address operator, IStrategy strategy, uint256 shares) external {}

    function decreaseDelegatedShares(address operator, IStrategy strategy, uint256 shares) external {}

    function delegationApprover(address /* operator */) external pure returns (address) {
        return address(0);
    }

    function delegationApproverSaltIsSpent(address _delegationApprover, bytes32 salt) external view returns (bool) {
        return delegationApproverSalts[_delegationApprover][salt];
    }

    function calculateCurrentStakerDelegationDigestHash(
        address staker,
        address operator,
        uint256 expiry
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(staker, operator, expiry));
    }

    function calculateStakerDelegationDigestHash(
        address staker,
        uint256 _stakerNonce,
        address operator,
        uint256 expiry
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(staker, _stakerNonce, operator, expiry));
    }

    function calculateDelegationApprovalDigestHash(
        address staker,
        address operator,
        address _delegationApprover,
        bytes32 approverSalt,
        uint256 expiry
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(staker, operator, _delegationApprover, approverSalt, expiry));
    }

    function operatorDetails(address /* operator */) external pure returns (OperatorDetails memory) {
        return OperatorDetails({
            __deprecated_earningsReceiver: address(0),
            delegationApprover: address(0),
            stakerOptOutWindowBlocks: 0
        });
    }

    function DOMAIN_TYPEHASH() external pure returns (bytes32) {
        return bytes32(0);
    }

    function STAKER_DELEGATION_TYPEHASH() external pure returns (bytes32) {
        return bytes32(0);
    }

    function DELEGATION_APPROVAL_TYPEHASH() external pure returns (bytes32) {
        return bytes32(0);
    }

    function beaconChainETHStrategy() external pure returns (IStrategy) {
        return IStrategy(address(0));
    }

    function domainSeparator() external pure returns (bytes32) {
        return bytes32(0);
    }

    function stakerNonce(address /* staker */) external pure returns (uint256) {
        return 0;
    }

    function cumulativeWithdrawalsQueued(address /* staker */) external pure returns (uint256) {
        return 0;
    }

    function calculateWithdrawalRoot(Withdrawal memory /* withdrawal */) external pure returns (bytes32) {
        return bytes32(0);
    }

    function getWithdrawalDelay(IStrategy[] calldata /* strategies */) external pure returns (uint256) {
        return 0;
    }

    function minWithdrawalDelayBlocks() external pure returns (uint256) {
        return 0;
    }

    function strategyWithdrawalDelayBlocks(IStrategy /* strategy */) external pure returns (uint256) {
        return 0;
    }

    function modifyOperatorDetails(OperatorDetails calldata /* newOperatorDetails */) external {}

    function updateOperatorMetadataURI(string calldata /* metadataURI */) external {}

    function queueWithdrawals(QueuedWithdrawalParams[] calldata /* queuedWithdrawalParams */)
        external
        pure
        returns (bytes32[] memory)
    {
        return new bytes32[](0);
    }

    function completeQueuedWithdrawal(
        Withdrawal calldata /* withdrawal */,
        IERC20[] calldata /* tokens */,
        uint256 /* middlewareTimesIndex */,
        bool /* receiveAsTokens */
    ) external {}

    function completeQueuedWithdrawals(
        Withdrawal[] calldata /* withdrawals */,
        IERC20[][] calldata /* tokens */,
        uint256[] calldata /* middlewareTimesIndexes */,
        bool[] calldata /* receiveAsTokens */
    ) external {}
}
