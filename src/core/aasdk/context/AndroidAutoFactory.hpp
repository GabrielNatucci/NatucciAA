#pragma once

#include <boost/asio.hpp>
#include <aasdk/Transport/ITransport.hpp>
#include <aasdk/Messenger/IMessenger.hpp>
#include <aasdk/Channel/Control/IControlServiceChannel.hpp>
#include <memory>

namespace natucci {
    class ControlChannelHandler;
    class VideoChannelHandler;
    class AudioChannelHandler;
    class InputChannelHandler;
}

namespace aasdk::channel::mediasink::video { class VideoMediaSinkService; }
namespace aasdk::channel::mediasink::audio { class AudioMediaSinkService; }
namespace aasdk::channel::inputsource { class InputSourceService; }

class AndroidAutoEntity {
public:
    virtual ~AndroidAutoEntity() = default;
    virtual void start() = 0;
    virtual void stop() = 0;
};

class AndroidAutoEntityImpl : public AndroidAutoEntity, public std::enable_shared_from_this<AndroidAutoEntityImpl> {
public:
    AndroidAutoEntityImpl(boost::asio::io_context& ioContext, aasdk::transport::ITransport::Pointer transport);
    ~AndroidAutoEntityImpl() override;

    void start() override;
    void stop() override;

private:
    boost::asio::io_context& ioContext_;
    aasdk::transport::ITransport::Pointer transport_;
    aasdk::messenger::IMessenger::Pointer messenger_;
    aasdk::messenger::ICryptor::Pointer cryptor_;
    
    std::shared_ptr<boost::asio::io_context::strand> strand_;
    aasdk::channel::control::IControlServiceChannel::Pointer controlChannel_;
    std::shared_ptr<natucci::ControlChannelHandler> controlHandler_;
    
    std::shared_ptr<aasdk::channel::mediasink::video::VideoMediaSinkService> videoChannel_;
    std::shared_ptr<natucci::VideoChannelHandler> videoHandler_;
    
    std::shared_ptr<aasdk::channel::mediasink::audio::AudioMediaSinkService> audioChannel_;
    std::shared_ptr<natucci::AudioChannelHandler> audioHandler_;
    
    std::shared_ptr<aasdk::channel::inputsource::InputSourceService> inputChannel_;
    std::shared_ptr<natucci::InputChannelHandler> inputHandler_;
};

class AndroidAutoFactory {
public:
    AndroidAutoFactory(boost::asio::io_context& ioContext);
    
    std::shared_ptr<AndroidAutoEntity> create(aasdk::transport::ITransport::Pointer transport);

private:
    boost::asio::io_context& ioContext_;
};
