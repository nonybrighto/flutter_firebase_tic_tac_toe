const functions = require('firebase-functions');
var admin = require('firebase-admin');
var app = admin.initializeApp();


// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//

exports.helloWorld = functions.https.onRequest((request, response) => {
    let name = request.query.name;
    response.send("Hello from Firebase!" + name);
});


exports.handleChallenge = functions.https.onRequest((request, response) => {
    
    let senderId = request.query.senderId;
    let senderName = request.query.senderName;
    let senderFcmToken = request.query.senderFcmToken;
    let receiverFcmToken = request.query.receiverFcmToken;
    let receiverId = request.query.receiverId;
    let receiverName = request.query.receiverName;
    let handleType = request.query.handleType;

    if(handleType === 'challenge'){
        let message = {
            data: {
                senderId: senderId,
                senderName: senderName,
                senderFcmToken: senderFcmToken,
                notificationType: 'challenge',
            },
        
            notification: {
                title: 'Tic Tac Toe Challenge',
                body : 'You just got a challenge from '+senderName
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

    }else if(handleType === 'accept'){

        //TODO: create the game of the two users and send notification to the two users
        //games_collection .. Id(combined_user_id) .. data  
        let gameId = receiverId+'_'+senderId;
        admin.firestore().collection('games').doc(gameId).set({
                //The player who sent the challenge is always player1 and will always be X.
              player1: {
                user: {
                    id: receiverId,
                    name: receiverName,
                },
                gamePiece: 'X',
                score: 0
              },
              player2: {
                user: {
                    id: senderId,
                    name: senderName,
                },
                gamePiece: 'O',
                score: 0
              },
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

        }).then((res) => {
              return admin.messaging().subscribeToTopic([senderFcmToken, receiverFcmToken], gameId);
        }).then((res) => {
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
                    body : 'Your game has been started!!!'
                }
            };
            return admin.messaging().sendToTopic(gameId,message);
          }).then((result) => {
                return response.send(true);
          }).catch((error) => {
            console.log('Error subscribing to topic:', error);
            response.send(false);
          });

    }else if(handleType === 'reject'){
         let message = {
            data: {
                senderId: senderId,
                senderFcmToken: senderFcmToken,
                notificationType: handleType,
            },
        
            notification: {
                title: 'Challenge Rejected!!',
                body : senderName+ 'rejected your challenge.'
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
