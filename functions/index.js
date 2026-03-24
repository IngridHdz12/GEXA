const {onValueUpdated} = require('firebase-functions/v2/database');
const admin = require('firebase-admin');
const {initializeApp} = require('firebase-admin/app');
const {getMessaging} = require('firebase-admin/messaging');

initializeApp();

// Función 1: Escuchar cambios en el nivel de gas de cada sensor individual
exports.monitorGasLevel = onValueUpdated(
    '/usuarios/{userId}/sensores/{sensorId}/valor',
    async (event) => {
      try {
        const gasLevel =
        (event.data && event.data.after && event.data.after.val()) || 0;

        const {userId, sensorId} = event.params; // 🔹 Te da el usuario y el sensor

        // Ahora el snapshot ya está en la ruta del usuario
        const sensorRef = admin.database().ref(`usuarios/${userId}/sensores/${sensorId}`);
        const sensorSnapshot = await sensorRef.once('value');

        if (!sensorSnapshot.exists()) {
          console.error(`Sensor ${sensorId} no encontrado en usuario ${userId}`);
          return;
        }

        const sensorData = sensorSnapshot.val();
        const nombreSensor = (sensorData && sensorData.nombre) ? sensorData.nombre : sensorId;

        if (gasLevel > 1795) {
          const message = {
            notification: {
              title: '¡Alerta de Gas!',
              body: `Sensor "${nombreSensor}" detectó ${gasLevel} ppm - NIVEL PELIGROSO`,
            },
            topic: 'gas_alert',
          };

          await getMessaging().send(message);
          console.log(`Notificación enviada para ${nombreSensor}`);
        }
      } catch (error) {
        console.error('Error completo:', error);
      }
    },
);


