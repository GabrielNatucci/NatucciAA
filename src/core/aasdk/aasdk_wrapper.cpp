#include "aasdk_wrapper.h"
#include <aasdk/Messenger/IMessenger.hpp>
#include <boost/asio/io_context.hpp>
#include <iostream>
#include "context/bluetooth/bluetooth_context.hpp"
#include <aasdk/Channel/Bluetooth/BluetoothService.hpp>
#include <memory>


struct AASDK_Context {
    bool is_running;
    BluetoothContext* btContext;

    // boost
    std::shared_ptr<boost::asio::io_context> ioContext;
    std::unique_ptr<boost::asio::io_context::strand> strand;

    aasdk::messenger::IMessenger::Pointer messenger;

    AASDK_Context() : is_running(false) {
        ioContext = std::make_shared<boost::asio::io_context>();
        strand = std::make_unique<boost::asio::io_context::strand>(*ioContext);
        btContext = initBtContext();

        // auto transport = std::make_shared<aasdk::transport::USBTransport>(usbWrapper);

        // auto transport = std::make_shared<aasdk::transport::USBTransport>(...);
    }

    ~AASDK_Context() {
    }
};

extern "C" {

AASDK_Context* aasdk_create_context(void) {
    try {
        AASDK_Context* ctx = new AASDK_Context();
        std::cout << "[Android auto wrapper] Contexto do AndroidAuto criado com sucesso!\n";
        return ctx;
    } catch (const std::exception& e) {
        std::cerr << "[Android auto wrapper] Erro ao criar contexto do AndroidAuto: " << e.what() << "\n";
        return nullptr;
    } catch (...) {
        std::cerr << "[Android auto wrapper] Erro desconhecido ao criar contexto do AndroidAuto.\n";
        return nullptr;
    }
}

void aasdk_destroy_context(AASDK_Context* ctx) {
    if (ctx != nullptr) {
        destroyBtContext(ctx->btContext);
        delete ctx;
        std::cout << "[Android auto wrapper] Contexto destruido.\n";
    }
}

int aasdk_start(AASDK_Context* ctx) {
    if (ctx == nullptr) return -1;

    if (!ctx->is_running) {
        ctx->is_running = true;
        std::cout << "[Android auto wrapper] AASDK iniciado.\n";
        return 0; // Success
    }

    return -2; // Already running
}

void aasdk_stop(AASDK_Context* ctx) {
    if (ctx == nullptr) return;

    // TODO: Implement actual stop logic using AASDK
    if (ctx->is_running) {
        ctx->is_running = false;
        std::cout << "[Android auto wrapper] AASDK parado.\n";
    }
}

} // extern "C"
