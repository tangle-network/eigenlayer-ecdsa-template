// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IAVSDirectory} from "@eigenlayer-contracts/interfaces/IAVSDirectory.sol";
import {ISignatureUtils} from "@eigenlayer-contracts/interfaces/ISignatureUtils.sol";
import {ISlasher} from "@eigenlayer-contracts/interfaces/ISlasher.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TestAVSDirectory is IAVSDirectory {
    bytes32 public constant OPERATOR_AVS_REGISTRATION_TYPEHASH =
        keccak256("OperatorAVSRegistration(address operator,address avs,bytes32 salt,uint256 expiry)");
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    mapping(address => mapping(address => OperatorAVSRegistrationStatus)) public avsOperatorStatus;
    mapping(address => mapping(bytes32 => bool)) public operatorSalts;

    function updateAVSMetadataURI(string calldata metadataURI) external {
        emit AVSMetadataURIUpdated(msg.sender, metadataURI);
    }

    function operatorSaltIsSpent(address operator, bytes32 salt) external view returns (bool) {
        return operatorSalts[operator][salt];
    }

    function registerOperatorToAVS(
        address operator,
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature
    ) external {
        bytes32 operatorRegistrationDigestHash = calculateOperatorAVSRegistrationDigestHash({
            operator: operator,
            avs: msg.sender,
            salt: operatorSignature.salt,
            expiry: operatorSignature.expiry
        });
        require(
            ECDSA.recover(operatorRegistrationDigestHash, operatorSignature.signature) == operator,
            "EIP1271SignatureUtils.checkSignature_EIP1271: signature not from signer"
        );
        avsOperatorStatus[msg.sender][operator] = OperatorAVSRegistrationStatus.REGISTERED;
        operatorSalts[operator][operatorSignature.salt] = true;
    }

    function deregisterOperatorFromAVS(address operator) external {
        avsOperatorStatus[msg.sender][operator] = OperatorAVSRegistrationStatus.UNREGISTERED;
    }

    function calculateOperatorAVSRegistrationDigestHash(address operator, address avs, bytes32 salt, uint256 expiry)
        public
        view
        returns (bytes32)
    {
        // calculate the struct hash
        bytes32 structHash = keccak256(abi.encode(OPERATOR_AVS_REGISTRATION_TYPEHASH, operator, avs, salt, expiry));
        // calculate the digest hash
        bytes32 digestHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator(), structHash));
        return digestHash;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("EigenLayer")), block.chainid, address(this)));
    }

    function cancelSalt(bytes32 salt) external {
        operatorSalts[msg.sender][salt] = true;
    }
}
