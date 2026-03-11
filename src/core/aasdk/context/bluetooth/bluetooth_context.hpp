#ifndef BLUETOOTH_CONTEXT_H
#define BLUETOOTH_CONTEXT_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct BluetoothContext BluetoothContext;

BluetoothContext* initBtContext(void);

void destroyBtContext(BluetoothContext* btContext);

int startBtContext(void);

void stopBtContext(void);

#ifdef __cplusplus
}
#endif

#endif /* AASDK_WRAPPER_H */
