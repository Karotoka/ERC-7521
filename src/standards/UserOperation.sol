// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

/* solhint-disable private-vars-leading-underscore */

import {BaseIntentStandard} from "../interfaces/BaseIntentStandard.sol";
import {IIntentStandard} from "../interfaces/IIntentStandard.sol";
import {UserIntent} from "../interfaces/UserIntent.sol";
import {IntentSolution, IntentSolutionLib} from "../interfaces/IntentSolution.sol";
import {Exec} from "../utils/Exec.sol";
import {getSegmentWord, getSegmentBytes} from "./utils/SegmentData.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";

/**
 * User Operation Intent Standard core logic
 * @dev data
 *   [bytes32] standard - the intent standard identifier
 *   [uint32]  callGasLimit - the max gas for executing the call
 *   [bytes]   callData - the calldata to call on the intent sender
 */
abstract contract BaseUserOperation is BaseIntentStandard {
    using IntentSolutionLib for IntentSolution;

    /**
     * Validate intent segment structure (typically just formatting).
     * @param segmentData the intent segment that is about to be solved.
     */
    function _validateIntentSegment(bytes calldata segmentData) internal pure virtual override {
        require(segmentData.length >= 36, "User Operation data is too small");
    }

    /**
     * Performs part or all of the execution for an intent.
     * @param solution the full solution being executed.
     * @param executionIndex the current index of execution (used to get the UserIntent to execute for).
     * @param segmentIndex the current segment to execute for the intent.
     * @param context context data from the previous step in execution (no data means execution is just starting).
     * @return context to remember for further execution.
     */
    function _executeIntentSegment(
        IntentSolution calldata solution,
        uint256 executionIndex,
        uint256 segmentIndex,
        bytes memory context
    ) internal virtual override returns (bytes memory) {
        UserIntent calldata intent = solution.intents[solution.getIntentIndex(executionIndex)];
        bytes calldata segment = intent.intentData[segmentIndex];
        if (segment.length > 36) {
            unchecked {
                uint32 callGasLimit = uint32(uint256(getSegmentWord(segment, 4)));
                bytes memory callData = getSegmentBytes(segment, 36, segment.length - 36);
                Exec.call(intent.sender, 0, callData, callGasLimit);
            }
        }

        //return context unchanged
        return context;
    }

    /**
     * Helper function to encode intent standard segment data.
     * @param standardId the entry point identifier for this standard
     * @param callGasLimit the max gas for executing the call
     * @param callData the calldata to call on the intent sender
     * @return the fully encoded intent standard segment data
     */
    function encodeData(bytes32 standardId, uint32 callGasLimit, bytes memory callData)
        external
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(standardId, callGasLimit, callData);
    }
}

/**
 * User Operation Intent Standard that can be deployed and registered to the entry point
 */
contract UserOperation is BaseUserOperation, IIntentStandard {
    function validateIntentSegment(bytes calldata segmentData) external pure override {
        BaseUserOperation._validateIntentSegment(segmentData);
    }

    function executeIntentSegment(
        IntentSolution calldata solution,
        uint256 executionIndex,
        uint256 segmentIndex,
        bytes calldata context
    ) external override returns (bytes memory) {
        return BaseUserOperation._executeIntentSegment(solution, executionIndex, segmentIndex, context);
    }
}

/**
 * User Operation Intent Standard that can be embedded in entry point
 */
contract EmbeddableUserOperation is BaseUserOperation {
    uint256 private constant _USER_OPERATION_STANDARD_ID = 1;
    bytes32 internal constant USER_OPERATION_STANDARD_ID = bytes32(_USER_OPERATION_STANDARD_ID);

    function getUserOperationStandardId() public pure returns (bytes32) {
        return USER_OPERATION_STANDARD_ID;
    }
}
