pragma solidity 0.8.20;

import "forge-std/Test.sol";
import {GaslitePoints} from "./../src/GaslitePoints.sol";

contract GaslitePointsTest is Test {
    GaslitePoints gaslitePoints;
    address user = vm.addr(1);

    function setUp() public {
        gaslitePoints = new GaslitePoints();
    }

    function test_addPoints() public {
        gaslitePoints.addPoints(user, 100);
        assertEq(gaslitePoints.points(user), 100);
    }

    function test_removePoints() public {
        gaslitePoints.addPoints(user, 100);
        gaslitePoints.removePoints(user, 50);
        assertEq(gaslitePoints.points(user), 50);
    }
}