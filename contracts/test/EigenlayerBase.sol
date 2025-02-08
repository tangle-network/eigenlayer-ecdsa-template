// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import "forge-std/src/Test.sol";

import {ISlasher} from "../src/interfaces/vendored/ISlasher.sol";
import {TestAVSDirectory} from "../src/test/TestAVSDirectory.sol";
import {TestDelegationManager} from "../src/test/TestDelegationManager.sol";
import {IDelegationManager} from "@eigenlayer-contracts/interfaces/IDelegationManager.sol";
import {TestSlasher} from "../src/test/TestSlasher.sol";

contract EigenlayerBase is Test {
    TestAVSDirectory internal avsDirectory;
    IDelegationManager internal delegationManager;
    ISlasher internal slasher;

    function _deployMockEigenLayerAndAVS() internal {
        avsDirectory = new TestAVSDirectory();
        delegationManager = IDelegationManager(address(new TestDelegationManager()));
        slasher = new TestSlasher();
    }
}
