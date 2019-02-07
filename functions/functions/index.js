const functions = require('firebase-functions');
var admin = require('firebase-admin');
var app = admin.initializeApp();


//NB: No major security feature implemented such as CSRF protection

exports.handleChallenge = functions.https.onRequest(async (request, response) => {

    let senderId = request.query.senderId;
    let senderName = request.query.senderName;
    let senderFcmToken = request.query.senderFcmToken;
    let receiverFcmToken = request.query.receiverFcmToken;
    let receiverId = request.query.receiverId;
    let receiverName = request.query.receiverName;
    let handleType = request.query.handleType;

    if (handleType === 'challenge') {
        let message = {
            data: {
                senderId: senderId,
                senderName: senderName,
                senderFcmToken: senderFcmToken,
                notificationType: 'challenge',
            },

            notification: {
                title: 'Tic Tac Toe Challenge',
                body: 'You just got a challenge from ' + senderName
            },

            token: receiverFcmToken
        };

        // Send a message to the device corresponding to the provided
        // registration token.
        admin.messaging().send(message)
        .then((res) => {
            // Response is a message ID string.
            console.log('Successfully sent message:', res);
            return response.send(true);
        })
        .catch((error) => {
            console.log('Error sending message:', error);
            response.send(false);
        });

    } else if (handleType === 'accept') {

        let gameId = receiverId + '_' + senderId;
        // Check if the game already exists, if the last game was won by someone, start a new one instead.
        // It shows that the game was completeda already

        let notificationMessage;
       try{
        let docSnapshot = admin.firestore().collection('games').doc(gameId).get();
        if(!docSnapshot.exists || (docSnapshot.exists && docSnapshot.data().winner !== '')){
            await _createGame(gameId, receiverId, receiverName, receiverFcmToken, senderId, senderName, senderFcmToken);
            await admin.messaging().subscribeToTopic([senderFcmToken, receiverFcmToken], gameId);
            notificationMessage = 'Your game has been started!!!';
        }else{
            notificationMessage = 'Your game is being continued!!!';
        }

        let message = {
            data: {
                player1Id: receiverId, // The player that sent the challenge is player1
                player2Id: senderId,
                player1Name: receiverName,
                player2Name: senderName,
                notificationType: 'started',
            },

            notification: {
                title: 'Game Started',
                body: notificationMessage
            }
        };
        await admin.messaging().sendToTopic(gameId, message);
        return response.send(true);

       }catch(err){
            console.log('Error subscribing to topic:', err);
            response.send(false);
       }

    } else if (handleType === 'reject') {
        let message = {
            data: {
                senderId: senderId,
                senderFcmToken: senderFcmToken,
                notificationType: handleType,
            },

            notification: {
                title: 'Challenge Rejected!!',
                body: senderName + 'rejected your challenge.'
            },

            token: receiverFcmToken
        };
        admin.messaging().send(message)
            .then((res) => {
                return response.send(true);
            })
            .catch((error) => {
                response.send(false);
            });
    }
});

exports.playPiece = functions.https.onRequest((request, response) => {

    let gameId = request.query.gameId;
    let playerId = request.query.playerId;
    let position = request.query.position;
    let piece = '';

    let pieceUpdateKey = 'pieces.' + position;
    let scoreUpdateKey = '';
    let playersCurrentScore = 0;

    admin.firestore().collection('games').doc(gameId).get().then((game) => {

        let gameData = {};
        if (game.exists && gameData.currentPlayer === playerId) {
            gameData = game.data()

            console.log('The collection response', game.data());

            //change the currentPLayer
            let nextPlayer = '';
            //TODO: refactor this and use gameData['player1'].gamePiece
            if (gameData.currentPlayer === gameData.player1.user.id) {
                nextPlayer = gameData.player2.user.id;
                piece = gameData.player1.gamePiece;
                scoreUpdateKey = 'player1.score';
                playersCurrentScore = gameData.player1.score;
            } else {
                nextPlayer = gameData.player1.user.id;
                piece = gameData.player2.gamePiece;
                scoreUpdateKey = 'player2.score';
                playersCurrentScore = gameData.player2.score;
            }

            let gamePiecesToTest = gameData.pieces;
            gamePiecesToTest[position] = piece;

            let winner = '';

            if (_isTie(gamePiecesToTest)) {
                winner = 'tie';
            } else if (_hasWin(gamePiecesToTest, piece)) {
                winner = playerId;
            }
            let gameUpdate = {
                currentPlayer: nextPlayer,
                [pieceUpdateKey]: piece

            };
            if (winner !== '') {
                gameUpdate.winner = winner;
            }
            if (winner !== '' && winner !== 'tie') {
                gameUpdate[scoreUpdateKey] = playersCurrentScore + 1;
            }
            return Promise.all([winner, nextPlayer, admin.firestore().collection('games').doc(gameId).update(gameUpdate)]);

        } else {
            return response.send('Not your turn');
        }
    }).then((result) => {

        let winner = result[0];
        let looser = result[1];
        console.log('Successfully played piece!');
        if (result[0] !== '' && result[0] !== 'tie') {

            return Promise.all([
                updatePointTransaction(winner, true),
                updatePointTransaction(looser, false),
            ]);
        }
        return response.send(true);
    }).then((result) => {
        console.log('Score has been updated sucessfully');
        return response.send(true);
    })
        .catch((err) => {
            console.log('Error playing piece:', err);
            response.send(false);
        });
});

exports.replayGame = functions.https.onRequest((request, response) => {

    let gameId = request.query.gameId;
    let playerId = request.query.playerId;


    admin.firestore().collection('games').doc(gameId).get().then((game) => {

        let gameData = {};
        if (game.exists) {

            gameData = game.data();

            if (gameData.winner !== ''
                && (gameData.player1.user.id !== playerId || gameData.player2.user.id !== playerId)) {

                return admin.firestore().collection('games').doc(gameId).update({
                    winner: '',
                    pieces: {
                        0: '',
                        1: '',
                        2: '',
                        3: '',
                        4: '',
                        5: '',
                        6: '',
                        7: '',
                        8: ''
                    }

                });

            } else {
                return response.status(403).send(false);
            }
        } else {
            console.log('not permitted');
            return response.status(404).send(false);
        }

    }).then((res) => {
        console.log('successfully updated the content');
        return response.send(true);
    })
        .catch((err) => {
            console.log('error during replay', err);
            response.status(500).send(false);
        });

});

exports.cancelGame = functions.https.onRequest((request, response) => {


    let gameId = request.query.gameId;
    let playerId = request.query.playerId;

    admin.firestore().collection('games').doc(gameId).get().then((game) => {

        let gameData = {};
        if (game.exists) {
            gameData = game.data();
            if (/*gameData.winner !== '' &&*/
                (gameData.player1.user.id !== playerId || gameData.player2.user.id !== playerId)) {
                console.log(gameData);
                return Promise.all([gameData.player1, gameData.player2, admin.firestore().collection('games').doc(gameId).delete()]);
            } else {
                return response.status(403).send(false);
            }
        } else {
            return response.status(404).send(false);
        }

    }).then((res) => {

        console.log(res);
        let player1 = res[0];
        let player2 = res[1];

        let message = {
            data: {
                notificationType: 'gameEnd',
            },

            notification: {
                title: 'Game ended',
                body: `Your game( ${player1.user.name} vs ${player2.user.name}) has been ended!!!`
            }
        };
        return Promise.all([admin.messaging().sendToTopic(gameId, message),
                        _changeUserState(player1.user.id, 'available'),
                        _changeUserState(player2.user.id, 'available')]);

    }).then((res) => {
        console.log('successfully cancelled');
        return response.send(true);
    }).catch(err => {
            console.log('error during game cancel', err);
            response.status(500).send(false);
        })


});

exports.onUserStatusChanged = functions.database.ref('/status/{userId}').onUpdate(
    (change, context) => {
      // Get the data written to Realtime Database
      const eventStatus = change.after.val();
      const usersRef = admin.firestore().collection('/users');

      return usersRef
            .doc(context.params.userId)
            .set({
              currentState: eventStatus.state
            }, { merge: true });
    });

function _isTie(pieces) {
    for (let key of Object.keys(pieces)) {
        if (pieces[key] === '') {
            console.log('tie false');
            return false;
        }
    }
    return true;
}

function _hasWin(pieces, playerPiece) {

    let possibleWins = [
        [0, 1, 2],
        [3, 4, 5],
        [6, 7, 8],
        [0, 3, 6],
        [1, 4, 7],
        [2, 5, 8],
        [0, 4, 8],
        [2, 4, 6]
    ];

    for (let i = 0; i < possibleWins.length; i++) {
        let currentPossibleWin = possibleWins[i];
        // String playerPiece = player.gamePiece.piece;
        if (pieces[currentPossibleWin[0]] === playerPiece &&
            pieces[currentPossibleWin[1]] === playerPiece &&
            pieces[currentPossibleWin[2]] === playerPiece) {
            console.log('win true');
            return true;
        }
    }
    console.log('win false');
    return false;
}

function _createGame(gameId, receiverId, receiverName, receiverFcmToken, senderId, senderName, senderFcmToken){
    return admin.firestore().collection('games').doc(gameId).set({
        //The player who sent the challenge is always player1 and will always be X.
        player1: {
            user: {
                id: receiverId,
                name: receiverName,
                fcmToken: receiverFcmToken
            },
            gamePiece: 'X',
            score: 0
        },
        player2: {
            user: {
                id: senderId,
                name: senderName,
                fcmToken: senderFcmToken
            },
            gamePiece: 'O',
            score: 0
        },
        winner: '',
        currentPlayer: receiverId,
        pieces: {
            0: '',
            1: '',
            2: '',
            3: '',
            4: '',
            5: '',
            6: '',
            7: '',
            8: ''
        }

    });
}


function _changeUserState(userId, state) {

    return admin.firestore().collection("users").doc(userId).set({
        currentState: state
    }, { merge: true });
}
