// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {Enrollment, EnrollmentStatus, EnumerableMapEnrollment} from "../libs/EnumerableMapEnrollment.sol";
import {HelloServiceManager} from "../HelloServiceManager.sol";

contract TestHelloServiceManager is HelloServiceManager {
    using EnumerableMapEnrollment for EnumerableMapEnrollment.AddressToEnrollmentMap;

    constructor(
        address _avsDirectory,
        address _stakeRegistry,
        address _paymentCoordinator,
        address _delegationManager,
        address _mailbox
    ) HelloServiceManager(_avsDirectory, _stakeRegistry, _delegationManager) {}

    function mockSetUnenrolled(address operator, address challenger) external {
        enrolledChallengers[operator].set(address(challenger), Enrollment(EnrollmentStatus.UNENROLLED, 0));
    }
}
