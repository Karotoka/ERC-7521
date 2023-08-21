// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../wallet/AbstractAccount.sol";

/**
 * @notice Abstract account implementation that sets a non-zero `validAfter` value for intents.
 */
contract TestAbstractAccount is AbstractAccount, Test {
    using ECDSA for bytes32;

    constructor(IEntryPoint entryPointAddr, IIntentStandard assetBasedIntentStandardAddr, address _owner)
        AbstractAccount(entryPointAddr, assetBasedIntentStandardAddr, _owner)
    {}

    function _validateSignature(UserIntent calldata intent, bytes32 intentHash)
        internal
        virtual
        override
        returns (uint256 validationData)
    {
        bytes32 hash = intentHash.toEthSignedMessageHash();
        if (owner != hash.recover(intent.signature)) {
            return _packValidationData(true, uint48(intent.timestamp), uint48(block.timestamp + 10));
        }
        return _packValidationData(false, uint48(intent.timestamp), uint48(block.timestamp + 10));
    }

    function test_nothing() public {}
}
