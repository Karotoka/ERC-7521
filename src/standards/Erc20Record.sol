// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {BaseIntentStandard} from "../interfaces/BaseIntentStandard.sol";
import {IIntentStandard} from "../interfaces/IIntentStandard.sol";
import {UserIntent} from "../interfaces/UserIntent.sol";
import {IntentSolution, IntentSolutionLib} from "../interfaces/IntentSolution.sol";
import {push} from "./utils/ContextData.sol";
import {getSegmentWord} from "./utils/SegmentData.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/**
 * ERC20 Record Intent Standard core logic
 * @dev data
 *   [bytes32] standard - the intent standard identifier
 *   [address] token - the ERC20 token contract address
 */
abstract contract BaseErc20Record is BaseIntentStandard {
    using IntentSolutionLib for IntentSolution;

    bytes32 private constant _TOKEN_ADDRESS_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;

    /**
     * Validate intent segment structure (typically just formatting).
     * @param segmentData the intent segment that is about to be solved.
     */
    function _validateIntentSegment(bytes calldata segmentData) internal pure virtual override {
        require(segmentData.length != 52, "ERC-20 Record data length invalid");
    }

    /**
     * Performs part or all of the execution for an intent.
     * @param solution the full solution being executed.
     * @param executionIndex the current index of execution (used to get the UserIntent to execute for).
     * @param segmentIndex the current segment to execute for the intent.
     * @param context context data from the previous step in execution (no data means execution is just starting).
     * @return newContext to remember for further execution.
     */
    function _executeIntentSegment(
        IntentSolution calldata solution,
        uint256 executionIndex,
        uint256 segmentIndex,
        bytes memory context
    ) internal view virtual override returns (bytes memory) {
        UserIntent calldata intent = solution.intents[solution.getIntentIndex(executionIndex)];
        address token =
            address(uint160(uint256(getSegmentWord(intent.intentData[segmentIndex], 20) & _TOKEN_ADDRESS_MASK)));

        //push current eth balance to the context data
        uint256 balance = IERC20(token).balanceOf(intent.sender);
        return push(context, bytes32(balance));
    }

    /**
     * Helper function to encode intent standard segment data.
     * @param standardId the entry point identifier for this standard
     * @param token the token contract address
     * @return the fully encoded intent standard segment data
     */
    function encodeData(bytes32 standardId, address token) external pure returns (bytes memory) {
        return abi.encodePacked(standardId, token);
    }
}

/**
 * ERC20 Record Intent Standard that can be deployed and registered to the entry point
 */
contract Erc20Record is BaseErc20Record, IIntentStandard {
    function validateIntentSegment(bytes calldata segmentData) external pure override {
        BaseErc20Record._validateIntentSegment(segmentData);
    }

    function executeIntentSegment(
        IntentSolution calldata solution,
        uint256 executionIndex,
        uint256 segmentIndex,
        bytes calldata context
    ) external view override returns (bytes memory) {
        return BaseErc20Record._executeIntentSegment(solution, executionIndex, segmentIndex, context);
    }
}
