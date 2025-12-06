// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NBAPredictions} from "../src/NBAPredictions.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract NBAPredictionsTest is Test {
    NBAPredictions public nbaPredictions;
    address public constant OWNER = address(0x1234);
    address public constant USER = address(0x5678);

    function setUp() public {
        vm.prank(OWNER);
        nbaPredictions = new NBAPredictions();
    }

    function test_MakePrediction() public {
        vm.prank(USER);
        nbaPredictions.makePrediction("Lakers", "Clippers", "Lakers");

        (
            uint256 gameId,
            string memory teamA,
            string memory teamB,
            string memory predictedWinner,
            address predictor,
            , // timestamp
            bool isSettled,
            string memory actualWinner
        ) = nbaPredictions.predictions(0);

        assertEq(gameId, 0);
        assertEq(teamA, "Lakers");
        assertEq(teamB, "Clippers");
        assertEq(predictedWinner, "Lakers");
        assertEq(predictor, USER);
        assertFalse(isSettled);
        assertEq(nbaPredictions.nextGameId(), 1);
    }

    function test_SettlePrediction_AsOwner() public {
        // First, a user makes a prediction
        vm.prank(USER);
        nbaPredictions.makePrediction("Warriors", "Nuggets", "Warriors");

        // Then, the owner settles it
        vm.prank(OWNER);
        nbaPredictions.settlePrediction(0, "Nuggets");

        (
            , // gameId
            , // teamA
            , // teamB
            , // predictedWinner
            , // predictor
            , // timestamp
            bool isSettled,
            string memory actualWinner
        ) = nbaPredictions.predictions(0);
        assertTrue(isSettled);
        assertEq(actualWinner, "Nuggets");
    }

    function test_Fail_SettlePrediction_AsNonOwner() public {
        vm.prank(USER);
        nbaPredictions.makePrediction("Celtics", "76ers", "Celtics");

        // Another user tries to settle, should fail
        vm.prank(address(0x9ABC));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0x9ABC)));
        nbaPredictions.settlePrediction(0, "Celtics");
    }

    function test_Events() public {
        // Test PredictionMade event
        vm.prank(USER);
        vm.expectEmit(true, true, true, true);
        emit NBAPredictions.PredictionMade(0, USER, "Suns", "Mavericks", "Suns");
        nbaPredictions.makePrediction("Suns", "Mavericks", "Suns");

        // Test PredictionSettled event
        vm.prank(OWNER);
        vm.expectEmit(true, false, false, true);
        emit NBAPredictions.PredictionSettled(0, "Mavericks");
        nbaPredictions.settlePrediction(0, "Mavericks");
    }
}
