// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {
    AssetCurve,
    evaluate,
    validate,
    parseAssetType,
    parseCurveType,
    parseEvaluationType,
    isRelativeEvaluation,
    CurveType,
    EvaluationType
} from "../utils/curves/AssetCurve.sol";
import {AssetType} from "../utils/wrappers/AssetWrapper.sol";

library AssetCurveLibHarness {
    function validateCurve(AssetCurve calldata curve) public pure {
        validate(curve);
    }

    function evaluateCurve(AssetCurve calldata curve, uint256 x) public pure returns (int256) {
        return evaluate(curve, x);
    }

    function parseAssetTypeOfCurve(AssetCurve calldata curve) public pure returns (AssetType) {
        return parseAssetType(curve);
    }

    function parseCurveTypeOfCurve(AssetCurve calldata curve) public pure returns (CurveType) {
        return parseCurveType(curve);
    }

    function parseEvaluationTypeOfCurve(AssetCurve calldata curve) public pure returns (EvaluationType) {
        return parseEvaluationType(curve);
    }

    function isCurveRelativeEvaluation(AssetCurve calldata curve) public pure returns (bool) {
        return isRelativeEvaluation(curve);
    }

    function testNothing() public {}
}
