// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

// ============ Internal Imports ============
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ECDSAServiceManagerBase} from "eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import {IRegistryCoordinator} from "eigenlayer-middleware/src/interfaces/IRegistryCoordinator.sol";

/// @title TangleTaskManager Contract
/// @dev This contract is responsible for managing tasks, responses, and interactions between the aggregator and task generator.
contract TangleTaskManager is ECDSAServiceManagerBase, OwnableUpgradeable {
    // ============ Events ============
    event NewTaskCreated(uint32 indexed taskIndex, Task task);
    event TaskResponded(TaskResponse taskResponse, TaskResponseMetadata taskResponseMetadata);
    event AggregatorUpdated(address indexed oldAggregator, address indexed newAggregator);
    event GeneratorUpdated(address indexed oldGenerator, address indexed newGenerator);

    // ============ Structs ============

    /// @dev Defines the structure of a task.
    struct Task {
        uint32 taskCreatedBlock;
        uint32 quorumThresholdPercentage;
        bytes message;
        bytes quorumNumbers;
    }

    // Task response is hashed and signed by operators.
    // these signatures are aggregated and sent to the contract as response.
    struct TaskResponse {
        // Can be obtained by the operator from the event NewTaskCreated.
        uint32 referenceTaskIndex;
        // This is just the response that the operator has to compute by itself.
        bytes message;
    }

    // Extra information related to taskResponse, which is filled inside the contract.
    // It thus cannot be signed by operators, so we keep it in a separate struct than TaskResponse
    // This metadata is needed by the challenger, so we emit it in the TaskResponded event
    struct TaskResponseMetadata {
        uint32 taskResponsedBlock;
        bytes32 hashOfNonSigners;
    }

    // ============ Constants ============
    uint256 internal constant _THRESHOLD_DENOMINATOR = 100;

    // The number of blocks from the task initialization within which the aggregator has to respond to
    uint32 public immutable TASK_RESPONSE_WINDOW_BLOCK;

    // ============ Storage ============
    // The latest task index
    uint32 public latestTaskNum;

    // mapping of task indices to all tasks hashes
    // when a task is created, task hash is stored here,
    // and responses need to pass the actual task,
    // which is hashed onchain and checked against this mapping
    mapping(uint32 => bytes32) public allTaskHashes;

    // mapping of task indices to hash of abi.encode(taskResponse, taskResponseMetadata)
    mapping(uint32 => bytes32) public allTaskResponses;

    address public aggregator;
    address public generator;

    // storage gap for upgradeability
    uint256[45] private __GAP;

    // ============ Modifiers ============

    /// @dev Modifier to allow only the aggregator to call certain functions.
    modifier onlyAggregator() {
        require(msg.sender == aggregator, "Aggregator must be the caller");
        _;
    }

    /// @dev Modifier to allow only the task generator to create new tasks.
    modifier onlyTaskGenerator() {
        require(msg.sender == generator, "Task generator must be the caller");
        _;
    }

    // ============ Constructor ============

    /// @notice Constructor to initialize the contract.
    /// @param _avsDirectory Address of the AVS directory
    /// @param _stakeRegistry Address of the stake registry
    /// @param _paymentCoordinator Address of the payment coordinator
    /// @param _delegationManager Address of the delegation manager
    /// @param _taskResponseWindowBlock Number of blocks within which the aggregator has to respond to a task.
    constructor(
        address _avsDirectory,
        address _stakeRegistry,
        address _paymentCoordinator,
        address _delegationManager,
        uint32 _taskResponseWindowBlock
    )
        ECDSAServiceManagerBase(
            _avsDirectory,
            _stakeRegistry,
            _paymentCoordinator,
            _delegationManager
        )
    {
        TASK_RESPONSE_WINDOW_BLOCK = _taskResponseWindowBlock;
    }

    // ============ Initializer ============

    /// @notice Initializes the contract with aggregator and generator addresses and transfers ownership.
    /// @param _owner Address of the initial owner.
    /// @param _aggregator Address of the aggregator.
    /// @param _generator Address of the task generator.
    /// @param _rewardsInitiator Address of the rewards initiator.
    function initialize(
        address _owner,
        address _aggregator,
        address _generator,
        address _rewardsInitiator
    ) public initializer {
        __ServiceManagerBase_init(_owner, _rewardsInitiator);
        _setAggregator(_aggregator);
        _setGenerator(_generator);
    }

    // ============ External Functions ============

    /// @notice Sets a new aggregator address.
    /// @dev Only callable by the contract owner.
    /// @param newAggregator Address of the new aggregator.
    function setAggregator(address newAggregator) external onlyOwner {
        _setAggregator(newAggregator);
    }

    /// @notice Sets a new generator address.
    /// @dev Only callable by the contract owner.
    /// @param newGenerator Address of the new task generator.
    function setGenerator(address newGenerator) external onlyOwner {
        _setGenerator(newGenerator);
    }

    /// @notice Creates a new task and assigns it a taskId.
    /// @param message Message payload of the task.
    /// @param quorumThresholdPercentage Minimum percentage of quorum required.
    /// @param quorumNumbers Numbers representing the quorum.
    /// @dev Only callable by the task generator.
    function createNewTask(
        bytes calldata message,
        uint32 quorumThresholdPercentage,
        bytes calldata quorumNumbers
    ) external onlyTaskGenerator {
        Task memory newTask;
        newTask.message = message;
        newTask.taskCreatedBlock = uint32(block.number);
        newTask.quorumThresholdPercentage = quorumThresholdPercentage;
        newTask.quorumNumbers = quorumNumbers;

        allTaskHashes[latestTaskNum] = keccak256(abi.encode(newTask));
        emit NewTaskCreated(latestTaskNum, newTask);
        latestTaskNum++;
    }

    /// @notice Responds to an existing task.
    /// @param task The task being responded to.
    /// @param taskResponse The response data to the task.
    /// @param nonSignerStakesAndSignature Signature and stakes of non-signers for verification.
    /// @dev Only callable by the aggregator.
    function respondToTask(
        Task calldata task,
        TaskResponse calldata taskResponse,
        NonSignerStakesAndSignature memory nonSignerStakesAndSignature
    ) external onlyAggregator {
        uint32 taskCreatedBlock = task.taskCreatedBlock;
        bytes calldata quorumNumbers = task.quorumNumbers;
        uint32 quorumThresholdPercentage = task.quorumThresholdPercentage;

        require(
            keccak256(abi.encode(task)) == allTaskHashes[taskResponse.referenceTaskIndex],
            "Supplied task does not match the one recorded in the contract"
        );
        require(
            allTaskResponses[taskResponse.referenceTaskIndex] == bytes32(0),
            "Aggregator has already responded to the task"
        );
        require(
            uint32(block.number) <= taskCreatedBlock + TASK_RESPONSE_WINDOW_BLOCK,
            "Aggregator has responded too late"
        );

        bytes32 message = keccak256(abi.encode(taskResponse));

        (QuorumStakeTotals memory quorumStakeTotals, bytes32 hashOfNonSigners) =
            checkSignatures(message, quorumNumbers, taskCreatedBlock, nonSignerStakesAndSignature);

        for (uint256 i = 0; i < quorumNumbers.length; i++) {
            require(
                quorumStakeTotals.signedStakeForQuorum[i] * _THRESHOLD_DENOMINATOR
                    >= quorumStakeTotals.totalStakeForQuorum[i] * uint8(quorumThresholdPercentage),
                "Signatories do not own at least threshold percentage of a quorum"
            );
        }

        TaskResponseMetadata memory taskResponseMetadata = TaskResponseMetadata(uint32(block.number), hashOfNonSigners);
        allTaskResponses[taskResponse.referenceTaskIndex] = keccak256(abi.encode(taskResponse, taskResponseMetadata));

        emit TaskResponded(taskResponse, taskResponseMetadata);
    }

    // ============ Internal Functions ============

    /// @dev Internal function to set a new task generator.
    /// @param newGenerator Address of the new generator.
    function _setGenerator(address newGenerator) internal {
        require(newGenerator != address(0), "Generator cannot be zero address");
        address oldGenerator = generator;
        generator = newGenerator;
        emit GeneratorUpdated(oldGenerator, newGenerator);
    }

    /// @dev Internal function to set a new aggregator.
    /// @param newAggregator Address of the new aggregator.
    function _setAggregator(address newAggregator) internal {
        require(newAggregator != address(0), "Aggregator cannot be zero address");
        address oldAggregator = aggregator;
        aggregator = newAggregator;
        emit AggregatorUpdated(oldAggregator, newAggregator);
    }
}
