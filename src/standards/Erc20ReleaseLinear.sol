// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {IIntentStandard} from "../interfaces/IIntentStandard.sol";
import {IIntentDelegate} from "../interfaces/IIntentDelegate.sol";
import {UserIntent} from "../interfaces/UserIntent.sol";
import {IntentSolution, IntentSolutionLib} from "../interfaces/IntentSolution.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {Erc20ReleaseDelegate} from "./delegates/Erc20ReleaseDelegate.sol";
import {popFromCalldata} from "./utils/ContextData.sol";
import {getSegmentWord} from "./utils/SegmentData.sol";
import {evaluateLinearCurve, encodeLinearCurve, encodeAsUint96, encodeAsUint64} from "./utils/CurveCoder.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/**
 * ERC20 Require with Linear Curve Intent Standard
 * @dev data
 *   [bytes32] standard - the intent standard identifier
 *   [address] token - the ERC20 token contract address
 *   [uint48]  startTime - start time of the curve (in seconds)
 *   [uint24]  deltaTime - amount of time from start until curve caps (in seconds)
 *   [uint96]  startAmount - starting amount
 *   [uint8]   startAmountMult - starting amount multiplier (final_amount = amount << amountMult)
 *   [uint64]  deltaAmount - amount of change after each second
 *   [uint8]   deltaAmountMult - delta amount multiplier (final_amount = amount << amountMult)
 *   [bytes1]  flags - negative [nnxx xxxx]
 */
contract Erc20ReleaseLinear is IIntentStandard, Erc20ReleaseDelegate {
    using IntentSolutionLib for IntentSolution;

    /**
     * Validate intent segment structure (typically just formatting).
     * @param segmentData the intent segment that is about to be solved.
     */
    function validateIntentSegment(bytes calldata segmentData) external pure {
        require(segmentData.length != 84, "ERC-20 Release Linear data length invalid");
    }

    /**
     * Performs part or all of the execution for an intent.
     * @param solution the full solution being executed.
     * @param executionIndex the current index of execution (used to get the UserIntent to execute for).
     * @param segmentIndex the current segment to execute for the intent.
     * @param context context data from the previous step in execution (no data means execution is just starting).
     * @return newContext to remember for further execution.
     */
    function executeIntentSegment(
        IntentSolution calldata solution,
        uint256 executionIndex,
        uint256 segmentIndex,
        bytes calldata context
    ) external returns (bytes memory) {
        UserIntent calldata intent = solution.intents[solution.getIntentIndex(executionIndex)];
        address token = address(
            uint160(
                uint256(
                    getSegmentWord(context, 20) & 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff
                )
            )
        );

        //evaluate data
        bytes32 data = getSegmentWord(intent.intentData[segmentIndex], 52);
        int256 releaseAmount = evaluateLinearCurve(data, solution.timestamp);

        //release
        address nextExecutingIntentSender = solution.intents[solution.getIntentIndex(executionIndex + 1)].sender;
        if (releaseAmount > 0) {
            bytes memory releaseEthDelegate =
                _encodeReleaseErc20(token, nextExecutingIntentSender, uint256(releaseAmount));
            IIntentDelegate(address(intent.sender)).generalizedIntentDelegateCall(releaseEthDelegate);
        }

        //return context unchanged
        return context;
    }

    /**
     * Helper function to encode intent standard segment data.
     * @param standardId the entry point identifier for this standard
     * @param token the ERC20 token contract address
     * @param startTime start time of the curve (in seconds)
     * @param deltaTime amount of time from start until curve caps (in seconds)
     * @param startAmount starting amount
     * @param deltaAmount amount of change after each second
     * @return the fully encoded intent standard segment data
     */
    function encodeData(
        bytes32 standardId,
        address token,
        uint48 startTime,
        uint24 deltaTime,
        int256 startAmount,
        int256 deltaAmount
    ) external pure returns (bytes memory) {
        (uint96 adjustedStartAmount, uint8 startMult, bool startNegative) = encodeAsUint96(startAmount);
        (uint64 adjustedDeltaAmount, uint8 deltaMult, bool deltaNegative) = encodeAsUint64(deltaAmount);
        bytes32 data = encodeLinearCurve(
            startTime,
            deltaTime,
            adjustedStartAmount,
            startMult,
            startNegative,
            adjustedDeltaAmount,
            deltaMult,
            deltaNegative,
            false
        );
        return abi.encodePacked(standardId, token, bytes32(data));
    }
}
