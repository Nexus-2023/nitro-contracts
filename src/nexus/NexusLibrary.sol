//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import {IDepositContract} from "./IDepositContract.sol";
import {INexusInterface} from "./INexusInterface.sol";

/**
 * @title Nexus Library
 * @author RohitAudit
 * @dev This is the library contract used by any bridge contract to integrate with Nexus Network without
 * adding addittional size to already contract
 */
contract NexusLibrary {
    address public constant NEXUS_NETWORK =
        0xc0cb8f6c08AB23de6c2a73c49481FE112704F1b6;
    address public constant NEXUS_FEE_ADDRESS =
        0x735bf02E4435dFADfE47a5FE5FBD42Ef375864A9;

    // slot to be calculated = keccak256("NAME_VARIABLE")
    bytes32 public constant AMOUNT_DEPOSITED_SLOT =
        0xca4e9536f4b6163e8b3c485d13888b64170049f120695cca4a7920674f669123;
    bytes32 public constant AMOUNT_WITHDRAWN_SLOT =
        0x0727682b75deaf0886514bd82c90f1c6e80521cdb4aeb9ed6f2ada2d5f20f112;
    bytes32 public constant AMOUNT_SLASHED_SLOT =
        0x67a602d91fdafa346635ea0b2cfecfa87c6c87b3eb52ac04414bcb5fffd82e5f;
    bytes32 public constant VALIDATOR_COUNT_SLOT =
        0x2d5a8d8ceecd33ab6923979e59fb92c16d966ad0b4d5ecdfb4adac6bafdd0ae5;
    bytes32 public constant NEXUS_FEE_PERCENTAGE_SLOT =
        0xac871e33a0d6f83ef496541ab4d2cb28c9c72346647360c557889bbd13ec109d;
    bytes32 public constant REWARDS_CLAIMED_SLOT =
        0x9fbc0f1af8e544d8995616c6f64d9fc6ca8bf8885fb0f08f57738b97334c0f73;

    // To be changed to the respective network addresses:
    address public constant DAO = 0x14630e0428B9BbA12896402257fa09035f9F7447;
    address public constant DEPOSIT_CONTRACT =
        0x4242424242424242424242424242424242424242;

    uint256 public constant VALIDATOR_DEPOSIT = 32 ether;
    uint256 public constant BASIS_POINT = 10000;
    error NotNexus();
    error IncorrectWithdrawalCredentials();
    error StakingLimitExceeding();
    error IncorrectNexusFee();
    error ValidatorNotExited();
    error WaitingForValidatorExits();
    error NotDAO();
    error IncorrectAmountSent();

    event RewardsRedeemed(uint256 amount);
    event SlashingUpdated(uint256 amount);
    event NexusFeeChanged(uint256 _nexus_fee);
    event NexusRewardsRedeemed(uint256 amount);

    modifier onlyNexus() {
        if (msg.sender != NEXUS_NETWORK) revert NotNexus();
        _;
    }

    modifier onlyDAO() {
        if (msg.sender != DAO) revert NotDAO();
        _;
    }

    modifier validNexusFee(uint256 _nexus_fee) {
        if (_nexus_fee > (BASIS_POINT) / 10 || _nexus_fee <= (BASIS_POINT) / 20)
            revert IncorrectNexusFee();
        _;
    }

    function setVariable(bytes32 _slot, uint256 amount) internal {
        assembly {
            sstore(_slot, amount)
        }
    }

    function getVariable(bytes32 _slot) public view returns (uint256) {
        uint256 variableValue;
        assembly {
            variableValue := sload(_slot)
        }
        return variableValue;
    }

    function updateExitedValidators() external onlyNexus {
        if (getRewards() < VALIDATOR_DEPOSIT) revert ValidatorNotExited();
        uint256 validatorCount = getVariable(VALIDATOR_COUNT_SLOT);
        validatorCount -= 1;
        setVariable(VALIDATOR_COUNT_SLOT, validatorCount);
    }

    function setNexusFee(
        uint256 _nexus_fee
    ) external onlyNexus validNexusFee(_nexus_fee) {
        setVariable(NEXUS_FEE_PERCENTAGE_SLOT, _nexus_fee);
        emit NexusFeeChanged(_nexus_fee);
    }

    function balance() external view returns(uint256){
        return (getVariable(AMOUNT_DEPOSITED_SLOT) - getVariable(AMOUNT_WITHDRAWN_SLOT));
    }

    function depositValidatorNexus(
        INexusInterface.Validator[] calldata _validators,
        uint256 stakingLimit
    ) external onlyNexus {
        uint256 validatorCount = getVariable(VALIDATOR_COUNT_SLOT);
        uint256 validators_balance = (validatorCount + _validators.length) *
            (VALIDATOR_DEPOSIT);
        if (((validators_balance * BASIS_POINT) /
                (address(this).balance + validators_balance)) > stakingLimit
        ) revert StakingLimitExceeding();
        for (uint i = 0; i < _validators.length; i++) {
            bytes memory withdrawalFromCred = _validators[i]
                .withdrawalAddress[12:];
            if (
                keccak256(withdrawalFromCred) !=
                keccak256(abi.encodePacked(address(this)))
            ) revert IncorrectWithdrawalCredentials();
            IDepositContract(DEPOSIT_CONTRACT).deposit{
                value: VALIDATOR_DEPOSIT
            }(
                _validators[i].pubKey,
                _validators[i].withdrawalAddress,
                _validators[i].signature,
                _validators[i].depositRoot
            );
        }
        validatorCount += _validators.length;
        setVariable(VALIDATOR_COUNT_SLOT, validatorCount);
    }

    function validatorsSlashed(uint256 amount) external onlyNexus {
        setVariable(AMOUNT_SLASHED_SLOT, amount);
        emit SlashingUpdated(amount);
    }

    function recieveExecutionRewards(uint256 amount) external payable {
        if(amount!=msg.value) revert IncorrectAmountSent();
    }

    function getRewards() public view returns (uint256) {
        uint256 validatorCount = getVariable(VALIDATOR_COUNT_SLOT);
        uint256 amountDeposited = getVariable(AMOUNT_DEPOSITED_SLOT);
        uint256 amountWithdrawn = getVariable(AMOUNT_WITHDRAWN_SLOT);
        uint256 slashedAmount = getVariable(AMOUNT_SLASHED_SLOT);
        return
            (address(this).balance + (validatorCount * VALIDATOR_DEPOSIT)) -
            (amountDeposited - amountWithdrawn) -
            slashedAmount;
    }

    function redeemRewards(
        address reward_account,
        uint256 expectedFee
    ) external onlyDAO {
        uint256 NexusFeePercentage = getVariable(NEXUS_FEE_PERCENTAGE_SLOT);
        if (expectedFee != NexusFeePercentage) revert IncorrectNexusFee();
        uint256 total_rewards = getRewards();
        if (total_rewards > VALIDATOR_DEPOSIT)
            revert WaitingForValidatorExits();
        uint256 _nexus_rewards = (NexusFeePercentage * total_rewards) /
            BASIS_POINT;
        (bool nexus_success, bytes memory nexus_data) = NEXUS_FEE_ADDRESS.call{
            value: _nexus_rewards,
            gas: 5000
        }("");
        if (nexus_success) {
            emit NexusRewardsRedeemed(_nexus_rewards);
        }
        (bool dao_success, bytes memory dao_data) = reward_account.call{
            value: (total_rewards - _nexus_rewards),
            gas: 5000
        }("");
        uint256 rewardsClaimed = getVariable(REWARDS_CLAIMED_SLOT);
        rewardsClaimed += total_rewards;
        setVariable(REWARDS_CLAIMED_SLOT, rewardsClaimed);
        if (dao_success) {
            emit RewardsRedeemed((total_rewards - _nexus_rewards));
        }
    }
}
