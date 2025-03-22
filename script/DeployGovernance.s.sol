//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EggheadToken} from "../src/dao/EggheadToken.sol";
import {EggheadGovernance} from "../src/dao/EggheadGovernance.sol";
import {TimeLock} from "../src/dao/TimeLock.sol";
import { Box } from "../src/dao/Box.sol";

contract DeployGovernance is Script {
    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600;

    address[] public proposers;
    address[] public executors;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("DEPLOYER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        EggheadToken govToken = new EggheadToken();
        govToken.mint(owner, INITIAL_SUPPLY);
        govToken.delegate(owner);

        TimeLock timeLock = new TimeLock(MIN_DELAY, proposers, executors, owner);

        EggheadGovernance governance = new EggheadGovernance(govToken, timeLock);

        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();

        timeLock.grantRole(proposerRole, address(governance));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(adminRole, owner);

        Box box = new Box(owner);
        box.transferOwnership(address(timeLock));

        vm.stopBroadcast();

        console.log("EggheadToken deployed at:", address(govToken));
        console.log("TimeLock deployed at:", address(timeLock));
        console.log("EggheadGovernance deployed at:", address(governance));
        console.log("Box deployed at:", address(box));
    }
}
