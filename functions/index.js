const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Cloud Function: Відправка push-сповіщень при створенні чекіну
 * 
 * Тригериться автоматично при створенні нового документа в колекції checkins
 */
exports.sendCheckinNotification = functions.firestore
  .document('checkins/{checkinId}')
  .onCreate(async (snap, context) => {
    const checkin = snap.data();
    const checkinId = context.params.checkinId;
    
    console.log(`Processing checkin: ${checkinId} from user: ${checkin.userId}`);
    
    // Отримати push-токени всіх отримувачів
    const recipientIds = checkin.recipientIds || [];
    
    if (recipientIds.length === 0) {
      console.log('No recipients found');
      return null;
    }
    
    // Зібрати всі push-токени
    const tokens = [];
    const userData = [];
    
    for (const recipientId of recipientIds) {
      try {
        const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
        
        if (userDoc.exists) {
          const user = userDoc.data();
          if (user.pushToken) {
            tokens.push(user.pushToken);
            userData.push({
              id: recipientId,
              name: user.name || 'Користувач',
              token: user.pushToken,
            });
          }
        }
      } catch (error) {
        console.error(`Error fetching user ${recipientId}:`, error);
      }
    }
    
    if (tokens.length === 0) {
      console.log('No push tokens found for recipients');
      return null;
    }
    
    // Отримати ім'я відправника
    let senderName = 'Хтось';
    try {
      const senderDoc = await admin.firestore().collection('users').doc(checkin.userId).get();
      if (senderDoc.exists) {
        senderName = senderDoc.data().name || 'Хтось';
      }
    } catch (error) {
      console.error(`Error fetching sender ${checkin.userId}:`, error);
    }
    
    // Визначити текст повідомлення залежно від статусу
    const statusText = {
      'ok': '💚 Я ОК',
      'busy': '💛 Все нормально, зайнятий',
      'later': '💙 Зателефоную пізніше',
      'hug': '🤍 Обійми',
    }[checkin.status] || '💚 Я ОК';
    
    // Формування повідомлення
    const message = {
      notification: {
        title: 'Я ОК',
        body: `${senderName}: ${statusText}`,
      },
      data: {
        type: 'checkin',
        checkinId: checkinId,
        userId: checkin.userId,
        status: checkin.status || 'ok',
        timestamp: checkin.timestamp || new Date().toISOString(),
      },
      tokens: tokens,
      android: {
        priority: 'high',
        notification: {
          channelId: 'yaok_channel',
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            alert: {
              title: 'Я ОК',
              body: `${senderName}: ${statusText}`,
            },
          },
        },
      },
    };
    
    try {
      // Відправити multicast повідомлення
      const response = await admin.messaging().sendMulticast(message);
      
      console.log(`✅ Sent ${response.successCount} notifications successfully`);
      console.log(`❌ Failed: ${response.failureCount} notifications`);
      
      // Логування помилок
      if (response.failureCount > 0) {
        const failedTokens = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
            console.error(`Failed to send to token ${tokens[idx]}:`, resp.error);
          }
        });
        
        // Видалити невалідні токени з бази
        if (failedTokens.length > 0) {
          await cleanupInvalidTokens(failedTokens);
        }
      }
      
      return { success: true, sent: response.successCount, failed: response.failureCount };
    } catch (error) {
      console.error('❌ Error sending notifications:', error);
      throw error;
    }
  });

/**
 * Cloud Function: Попередження про відсутність зв'язку
 * 
 * Запускається по розкладу (через Cloud Scheduler) або HTTP тригером
 */
exports.checkMissingCheckins = functions.pubsub
  .schedule('every 24 hours')
  .timeZone('Europe/Kyiv')
  .onRun(async (context) => {
    console.log('Checking for missing checkins...');
    
    const now = admin.firestore.Timestamp.now();
    const threeDaysAgo = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 3 * 24 * 60 * 60 * 1000
    );
    
    try {
      // Отримати всіх активних користувачів
      const usersSnapshot = await admin.firestore().collection('users').get();
      
      for (const userDoc of usersSnapshot.docs) {
        const user = userDoc.data();
        const userId = userDoc.id;
        
        // Отримати останній чекін користувача
        const lastCheckinSnapshot = await admin.firestore()
          .collection('checkins')
          .where('userId', '==', userId)
          .orderBy('timestamp', 'desc')
          .limit(1)
          .get();
        
        if (lastCheckinSnapshot.empty) {
          // Користувач ніколи не робив чекін
          continue;
        }
        
        const lastCheckin = lastCheckinSnapshot.docs[0].data();
        const lastCheckinTime = lastCheckin.timestamp;
        
        // Перевірити, чи останній чекін був більше 3 днів тому
        if (lastCheckinTime.toMillis() < threeDaysAgo.toMillis()) {
          // Відправити попередження контактам
          const contactIds = user.contactIds || [];
          
          if (contactIds.length > 0) {
            await sendMissingCheckinWarning(userId, user.name || 'Користувач', contactIds, lastCheckinTime);
          }
        }
      }
      
      console.log('✅ Missing checkins check completed');
      return null;
    } catch (error) {
      console.error('❌ Error checking missing checkins:', error);
      throw error;
    }
  });

/**
 * Допоміжна функція: Відправка попередження про відсутність зв'язку
 */
async function sendMissingCheckinWarning(userId, userName, contactIds, lastCheckinTime) {
  const tokens = [];
  
  for (const contactId of contactIds) {
    try {
      const contactDoc = await admin.firestore().collection('users').doc(contactId).get();
      if (contactDoc.exists && contactDoc.data().pushToken) {
        tokens.push(contactDoc.data().pushToken);
      }
    } catch (error) {
      console.error(`Error fetching contact ${contactId}:`, error);
    }
  }
  
  if (tokens.length === 0) return;
  
  const daysAgo = Math.floor(
    (Date.now() - lastCheckinTime.toMillis()) / (24 * 60 * 60 * 1000)
  );
  
  const message = {
    notification: {
      title: '⚠️ Попередження',
      body: `${userName} не виходив на зв'язок ${daysAgo} днів`,
    },
    data: {
      type: 'missing_checkin',
      userId: userId,
      daysAgo: daysAgo.toString(),
    },
    tokens: tokens,
  };
  
  try {
    await admin.messaging().sendMulticast(message);
    console.log(`Sent missing checkin warning for user ${userId}`);
  } catch (error) {
    console.error(`Error sending warning for user ${userId}:`, error);
  }
}

/**
 * Допоміжна функція: Очищення невалідних push-токенів
 */
async function cleanupInvalidTokens(invalidTokens) {
  const usersSnapshot = await admin.firestore().collection('users').get();
  
  for (const userDoc of usersSnapshot.docs) {
    const user = userDoc.data();
    if (user.pushToken && invalidTokens.includes(user.pushToken)) {
      try {
        await admin.firestore().collection('users').doc(userDoc.id).update({
          pushToken: admin.firestore.FieldValue.delete(),
        });
        console.log(`Removed invalid token for user ${userDoc.id}`);
      } catch (error) {
        console.error(`Error removing token for user ${userDoc.id}:`, error);
      }
    }
  }
}

/**
 * HTTP Function: Тестова функція для перевірки
 */
exports.healthCheck = functions.https.onRequest((req, res) => {
  res.json({
    status: 'ok',
    message: 'Я ОК Cloud Functions are running',
    timestamp: new Date().toISOString(),
  });
});
