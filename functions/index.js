const {onValueUpdated} = require('firebase-functions/v2/database');
const functions = require('firebase-functions');

const {initializeApp} = require('firebase-admin/app');
const {getMessaging} = require('firebase-admin/messaging');

initializeApp();

// Función 1: Escuchar cambios en el nivel de gas de cada sensor individual
exports.monitorGasLevel = onValueUpdated('/sensor_gas/{sensorId}/valor', async (event) => {
  try {
    const gasLevel = event.data?.after?.val() || 0;
    const sensorId = event.params.sensorId;

    // 1. Obtener el nombre del sensor
    const userId = 'kIBSZ9ufCWVN4YiDVgdAZCxRUqA3'; // Tu usuario específico
    const sensorRef = admin.database().ref(`usuarios/${userId}/sensores/${sensorId}`);
    const sensorSnapshot = await sensorRef.once('value');
    
    // Verificación exhaustiva
    if (!sensorSnapshot.exists()) {
      console.error(`Sensor ${sensorId} no encontrado en usuario ${userId}`);
      return;
    }

    const sensorData = sensorSnapshot.val();
    const nombreSensor = sensorData?.nombre || sensorId; // Fallback al ID si no hay nombre

    console.log('Datos completos del sensor:', sensorData); // Debug
    console.log(`Nombre extraído: ${nombreSensor}`); // Debug

    // 2. Lógica de notificación
    if (gasLevel > 300) {
      const message = {
        notification: {
          title: '¡Alerta de Gas!',
          body: `Sensor "${nombreSensor}" detectó ${gasLevel} ppm - NIVEL PELIGROSO`
        },
        topic: 'gas_alert'
      };

      await getMessaging().send(message);
      console.log(`Notificación enviada para ${nombreSensor}`);
    }
  } catch (error) {
    console.error('Error completo:', error);
  }
});

// Función 2: Enviar alerta manual desde app Flutter
exports.enviarAlertaGas = functions.https.onRequest(async (req, res) => {
  const message = {
    notification: {
      title: '¡Alerta de gas!',
      body: 'Nivel peligroso detectado',
    },
    topic: 'gas_alert',
  };

  try {
    await getMessaging().send(message);
    res.status(200).send('Notificación enviada');
  } catch (error) {
    console.error(error);
    res.status(500).send('Error enviando la notificación');
  }
});
