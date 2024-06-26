//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {ISSVNetworkCore} from "./ISSVNetwork.sol";

interface INexusInterface {
    // structs to be used for nexus interface
    // todo: add multiple operator cluster mapping so that rollup can select cluster and percentage per cluster
    struct Rollup {
        address bridgeContract;
        uint16 stakingLimit;
        uint64 operatorCluster;
    }
    struct Validator {
        bytes pubKey;
        bytes withdrawalAddress;
        bytes signature;
        bytes32 depositRoot;
    }
    struct ValidatorShares {
        bytes pubKey;
        uint64[] operatorIds;
        bytes sharesEncrypted;
        uint256 amount;
        ISSVNetworkCore.Cluster cluster;
    }

    enum ValidatorStatus{
        INACTIVE,
        DEPOSITED,
        SHARE_DEPOSITED,
        VALIDATOR_EXIT_SUBMITTED,
        VALIDATOR_EXITED
    }

    // errors
    error NotNexusBot();
    error AddressAlreadyWhitelisted();
    error AddressNotWhitelisted();
    error RollupAlreadyPresent();
    error RollupAlreadyRegistered();
    error KeyNotDeposited();
    error NexusAddressNotFound();
    error InvalidKeySupplied();
    error ClusterAlreadyExited();
    error IncorrectStakingLimit();
    error IncorrectValidatorStatus();

    // events
    event RollupWhitelisted(string name, address rollupAddress);
    event RollupRegistered(address rollupAdmin, address withdrawalAddress,uint16 stakingLimit,uint64 operatorCluster,uint256 nexusFee);
    event StakingLimitChanged(address rollupAdmin,uint16 StakingLimit);
    event RollupOperatorClusterChanged(address rollup_admin,uint64 operatorCluster);
    event NexusFeeChanged(address rollup_admin,uint256 newFee);
    event ValidatorSubmitted(bytes pubKey, address rolupAdmin);
    event ValidatorShareSubmitted(bytes pubKey, address rolupAdmin,uint256 amount);
    event ClusterAdded(uint64 clusterId, uint64[] operatorIds);
    event SSVRecharged(address sender, uint256 amount);
    event ClusterRecharged(uint64 clusterId,uint256 amount);
    event RollupValidatorSlashed(address admin,uint256 amount);
    event ValidatorExitSubmitted(address admin,bytes pubKey);
    event ValidatorExited(address admin,bytes pubKey);
    event NodeOperatorContractChanged(address _nodeOperatorContract);

    // functions
    function depositValidatorRollup(
        address _rollupAdmin,
        Validator[] calldata _validators
    ) external;

    function depositValidatorShares(
        address _rollupAdmin,
        ValidatorShares calldata _validatorShare
    ) external;

}
