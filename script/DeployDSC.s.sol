//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/defi/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/defi/DSCEngine.sol";
import {DSCHelperConfig} from "./DSCHelperConfig.s.sol";

contract DeployDSC is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function run() external returns (DecentralizedStableCoin, DSCEngine, DSCHelperConfig) {
        DSCHelperConfig config = new DSCHelperConfig();

        (address wethUsdPriceFeed, address wbtcUsdPriceFeed, address weth, address wbtc,) = config.activeNetworkConfig();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];

        vm.startBroadcast();
        DecentralizedStableCoin dsc = new DecentralizedStableCoin();
        DSCEngine dscEngine = new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));

        dsc.transferOwnership(address(dscEngine));
        vm.stopBroadcast();

        // console.log("DeployDSC / dsc: ", address(dsc));
        // console.log("DeployDSC / dscEngine: ", address(dscEngine));

        return (dsc, dscEngine, config);
    }
}
