//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISSVNetworkCore {
    /// @notice Represents a cluster of validators
    struct Cluster {
        /// @dev The number of validators in the cluster
        uint32 validatorCount;
        /// @dev The index of network fees related to this cluster
        uint64 networkFeeIndex;
        /// @dev The last index calculated for the cluster
        uint64 index;
        /// @dev Flag indicating whether the cluster is active
        bool active;
        /// @dev The balance of the cluster
        uint256 balance;
    }

    /********************************/
    /* Validator External Functions */
    /********************************/

    function registerValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        bytes calldata sharesEncrypted,
        uint256 amount,
        Cluster memory cluster
    ) external;

    function exitValidator(bytes calldata publicKey, uint64[] calldata operatorIds) external;

    function removeValidator(
        bytes calldata publicKey,
        uint64[] memory operatorIds,
        Cluster memory cluster
    ) external;

    function deposit(
        address clusterOwner,
        uint64[] calldata operatorIds,
        uint256 amount,
        ISSVNetworkCore.Cluster memory cluster
    ) external;

    function setFeeRecipientAddress(address feeRecipientAddress) external;

}
