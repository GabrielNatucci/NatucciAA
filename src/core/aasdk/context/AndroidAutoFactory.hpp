#pragma once

#include <boost/asio.hpp>
#include <aasdk/Transport/ITransport.hpp>
#include <aasdk/Messenger/IMessenger.hpp>
#include <memory>

class AndroidAutoEntity {
public:
    virtual ~AndroidAutoEntity() = default;
    virtual void start() = 0;
    virtual void stop() = 0;
};

class AndroidAutoEntityImpl : public AndroidAutoEntity {
public:
    AndroidAutoEntityImpl(boost::asio::io_context& ioContext, aasdk::transport::ITransport::Pointer transport);
    ~AndroidAutoEntityImpl() override;

    void start() override;
    void stop() override;

private:
    boost::asio::io_context& ioContext_;
    aasdk::transport::ITransport::Pointer transport_;
    aasdk::messenger::IMessenger::Pointer messenger_;
};

class AndroidAutoFactory {
public:
    AndroidAutoFactory(boost::asio::io_context& ioContext);
    
    std::shared_ptr<AndroidAutoEntity> create(aasdk::transport::ITransport::Pointer transport);

private:
    boost::asio::io_context& ioContext_;
};
