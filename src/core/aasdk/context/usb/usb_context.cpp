#include "usb_context.hpp"
#include <iostream>
#include <aasdk/USB/AOAPDevice.hpp>

UsbContext::UsbContext(boost::asio::io_context& ioContext) : libusbCtx(nullptr), ioContext_(ioContext) {
    if (libusb_init(&libusbCtx) != LIBUSB_SUCCESS) {
        throw std::runtime_error("Failed to initialize libusb");
    }

    usbWrapper = std::make_shared<aasdk::usb::USBWrapper>(libusbCtx);
    queryFactory = std::make_shared<aasdk::usb::AccessoryModeQueryFactory>(*usbWrapper, ioContext_);
    queryChainFactory = std::make_shared<aasdk::usb::AccessoryModeQueryChainFactory>(*usbWrapper, ioContext_, *queryFactory);
    usbHub = std::make_shared<aasdk::usb::USBHub>(*usbWrapper, ioContext_, *queryChainFactory);
    this->enumerator = std::make_shared<aasdk::usb::ConnectedAccessoriesEnumerator>(
        *usbWrapper, 
        ioContext_, 
        *queryChainFactory
    );
}

UsbContext::~UsbContext() {
    stop();
    if (libusbCtx) {
        libusb_exit(libusbCtx);
        libusbCtx = nullptr;
    }
}

void UsbContext::start() {
    startDeviceDiscovery();

    auto enumPromise = aasdk::usb::IConnectedAccessoriesEnumerator::Promise::defer(ioContext_);
    enumPromise->then([](bool success) {
        std::cout << "[UsbContext] Enumerator finalizou: " << (success ? "sucesso" : "falha") << "\n";
    }, [](const aasdk::error::Error& error) {
        std::cerr << "[UsbContext] Enumerator erro: " << error.what() << "\n";
    });

    std::cout << "[UsbContext] Procurando dispositivos já plugados...\n";
    this->enumerator->enumerate(enumPromise);
}

void UsbContext::stop() {
    if (usbHub) {
        usbHub->cancel();
    }
    if (usbTransport) {
        usbTransport->stop();
        usbTransport.reset();
    }
}

void UsbContext::startDeviceDiscovery() {
    std::cout << "\n[UsbContext] Começando usb discovery\n";
    auto promise = aasdk::usb::IUSBHub::Promise::defer(ioContext_);

    promise->then([this](aasdk::usb::DeviceHandle handle) {
        std::cout << "[UsbContext DISP CONECTADO] AOAP conectado!\n";
        auto aoapDevice = aasdk::usb::AOAPDevice::create(*usbWrapper, ioContext_, handle);
        usbTransport = std::make_shared<aasdk::transport::USBTransport>(ioContext_, aoapDevice);
        
        // TODO: Start the Messenger and Session using this transport
    }, [this](const aasdk::error::Error& error) {
        std::cerr << "[UsbContext] Device discovery failed or cancelled. Error: " << error.what() << "\n";
    });

    usbHub->start(promise);
}

extern "C" {
    UsbContext* initUsbContext(boost::asio::io_context& ioContext) {
        try {
            UsbContext* ctx = new UsbContext(ioContext);
            std::cout << "[UsbContext] criado com sucesso!\n";
            return ctx;
        } catch (...) {
            std::cerr << "Erro ao criar o [UsbContext]\n";
            return nullptr;
        }
    }

    void destroyUsbContext(UsbContext* usbContext) {
        if (usbContext != nullptr) {
            delete usbContext;
            std::cout << "[UsbContext] destruido com sucesso!\n";
        }
    }

    int startUsbContext(UsbContext* usbContext) {
        if (usbContext == nullptr) return -1;
        usbContext->start();
        std::cout << "[UsbContext] iniciado com sucesso!\n\n";
        return 1;
    }

    void stopUsbContext(UsbContext* usbContext) {
        if (usbContext != nullptr) {
            usbContext->stop();
            std::cout << "[UsbContext] parado com sucesso!\n";
        }
    }
}
