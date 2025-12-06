// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract NBAPredictions is Ownable {
    struct Prediction {
        uint256 gameId;
        string teamA;
        string teamB;
        string predictedWinner;
        address predictor;
        uint256 timestamp;
        bool isSettled;
        string actualWinner;
    }

    mapping(uint256 => Prediction) public predictions;
    uint256 public nextGameId;

    event PredictionMade(
        uint256 indexed gameId,
        address indexed predictor,
        string teamA,
        string teamB,
        string predictedWinner
    );
    event PredictionSettled(uint256 indexed gameId, string actualWinner);

    constructor() Ownable(msg.sender) {}

    function makePrediction(
        string memory _teamA,
        string memory _teamB,
        string memory _predictedWinner
    ) public {
        uint256 gameId = nextGameId;
        predictions[gameId] = Prediction({
            gameId: gameId,
            teamA: _teamA,
            teamB: _teamB,
            predictedWinner: _predictedWinner,
            predictor: msg.sender,
            timestamp: block.timestamp,
            isSettled: false,
            actualWinner: ""
        });
        nextGameId++;
        emit PredictionMade(gameId, msg.sender, _teamA, _teamB, _predictedWinner);
    }

    function settlePrediction(uint256 _gameId, string memory _actualWinner) public onlyOwner {
        require(predictions[_gameId].timestamp != 0, "Prediction does not exist");
        require(!predictions[_gameId].isSettled, "Prediction already settled");

        Prediction storage predictionToSettle = predictions[_gameId];
        predictionToSettle.isSettled = true;
        predictionToSettle.actualWinner = _actualWinner;

        emit PredictionSettled(_gameId, _actualWinner);
    }
}
