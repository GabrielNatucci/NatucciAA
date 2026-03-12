#include "bluetooth_context.hpp"
#include <iostream>
#include <aasdk/Channel/Bluetooth/BluetoothService.hpp>
#include <memory>

struct BluetoothContext {
    std::unique_ptr<aasdk::channel::bluetooth::IBluetoothService> btService;

    BluetoothContext() {
    //     btService = std::make_unique<aasdk::channel::bluetooth::BluetoothService>();
    }

    ~BluetoothContext() {
    }
};

extern "C"{
BluetoothContext* initBtContext(void) {
    try  {
        BluetoothContext* btCont = new BluetoothContext();
        std::cout << "[BluetoothContext] criado com sucesso!\n";
        return btCont;
    } catch (...) {
        std::cerr << "Erro ao criar o [BluetoothContext]\n";
        return nullptr;
    }

}

void destroyBtContext(BluetoothContext* btContext) {
    if (btContext != nullptr) {
        delete btContext;
        std::cout << "[BluetoothContext] destruido com sucesso!\n";
    }
}

int startBtContext(void) {

    std::cout << "[BluetoothContext] iniciado com sucesso!\n";
    return 1;
}

void stopBtContext(void) {
    std::cout << "[BluetoothContext] parado com sucesso!\n";
}

}
