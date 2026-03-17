#ifndef USB_CONTEXT_HPP
#define USB_CONTEXT_HPP

#include <aasdk/USB/USBHub.hpp>
#include <aasdk/USB/USBWrapper.hpp>
#include <aasdk/USB/AccessoryModeQueryChainFactory.hpp>
#include <aasdk/USB/AccessoryModeQueryFactory.hpp>
#include <aasdk/Transport/USBTransport.hpp>
#include <boost/asio.hpp>
#include <memory>
#include <libusb-1.0/libusb.h>

struct UsbContext {
    libusb_context* libusbCtx;
    std::shared_ptr<aasdk::usb::USBWrapper> usbWrapper;
    std::shared_ptr<aasdk::usb::AccessoryModeQueryFactory> queryFactory;
    std::shared_ptr<aasdk::usb::AccessoryModeQueryChainFactory> queryChainFactory;
    std::shared_ptr<aasdk::usb::USBHub> usbHub;
    std::shared_ptr<aasdk::transport::USBTransport> usbTransport;
    boost::asio::io_context& ioContext_;

    UsbContext(boost::asio::io_context& ioContext);
    ~UsbContext();

    void start();
    void stop();

private:
    void startDeviceDiscovery();
};

extern "C" {
    UsbContext* initUsbContext(boost::asio::io_context& ioContext);
    void destroyUsbContext(UsbContext* usbContext);
    int startUsbContext(UsbContext* usbContext);
    void stopUsbContext(UsbContext* usbContext);
}

#endif // USB_CONTEXT_HPP
