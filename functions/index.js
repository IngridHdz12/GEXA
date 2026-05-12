const {onValueUpdated} = require('firebase-functions/v2/database');
const admin = require('firebase-admin');
const {initializeApp} = require('firebase-admin/app');
const {getMessaging} = require('firebase-admin/messaging');

initializeApp();

exports.monitorGasLevel = onValueUpdated(
    '/usuarios/{userId}/sensores/{sensorId}/valor',
    async (event) => {
      try {
        const gasLevel = (event.data && event.data.after && event.data.after.val()) || 0;
        const {userId, sensorId} = event.params;

        const sensorRef = admin.database().ref(`usuarios/${userId}/sensores/${sensorId}`);
        const sensorSnapshot = await sensorRef.once('value');

        if (!sensorSnapshot.exists()) return;

        const sensorData = sensorSnapshot.val();
        const nombreSensor = (sensorData && sensorData.nombre) ? sensorData.nombre : sensorId;

        if (gasLevel > 1795) {
          const message = {
            
            data: {
              title: '¡ALERTA DE GAS!',
              body: `Sensor "${nombreSensor}" detectó ${gasLevel} ppm - NIVEL PELIGROSO`,
              tipo: 'alerta_critica' // Etiqueta para que Flutter sepa qué hacer
            },
            android: {
              priority: 'high', // Despierta el dispositivo inmediatamente
              
            },
            topic: 'gas_alert',
          };

          await getMessaging().send(message);
          console.log(`Mensaje de datos enviado para ${nombreSensor}`);
        }
      } catch (error) {
        console.error('Error completo:', error);
      }
    },
);