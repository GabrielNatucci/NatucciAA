#include <aasdk/USB/USBWrapper.hpp>
#include <aasdk/USB/USBHub.hpp>
#include <aasdk/USB/AccessoryModeQueryChainFactory.hpp>
#include <aasdk/USB/AccessoryModeQueryFactory.hpp>
#include <aasdk/USB/ConnectedAccessoriesEnumerator.hpp>
#include <aasdk/Transport/USBTransport.hpp>
#include <boost/asio.hpp>
#include <libusb-1.0/libusb.h>

int main() {
    libusb_context* libusb_ctx = nullptr;
    libusb_init(&libusb_ctx);

    boost::asio::io_context io_context;
    boost::asio::io_context::strand strand(io_context);

    auto usbWrapper = std::make_shared<aasdk::usb::USBWrapper>(libusb_ctx);
    auto queryFactory = std::make_shared<aasdk::usb::AccessoryModeQueryFactory>(*usbWrapper, io_context);
    auto queryChainFactory = std::make_shared<aasdk::usb::AccessoryModeQueryChainFactory>(*usbWrapper, io_context, *queryFactory);
    
    auto usbHub = std::make_shared<aasdk::usb::USBHub>(*usbWrapper, io_context, *queryChainFactory);
    
    return 0;
}
