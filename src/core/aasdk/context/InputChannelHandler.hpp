#pragma once

#include <aasdk/Channel/InputSource/IInputSourceServiceEventHandler.hpp>
#include <aasdk/Channel/InputSource/InputSourceService.hpp>
#include <aap_protobuf/service/control/message/ChannelOpenRequest.pb.h>
#include <aap_protobuf/service/control/message/ChannelOpenResponse.pb.h>
#include <aap_protobuf/service/media/sink/message/KeyBindingRequest.pb.h>
#include <aap_protobuf/service/media/sink/message/KeyBindingResponse.pb.h>
#include <iostream>

namespace natucci {

    class InputChannelHandler : public aasdk::channel::inputsource::IInputSourceServiceEventHandler {
    public:
        InputChannelHandler(boost::asio::io_context::strand& strand, std::shared_ptr<aasdk::channel::inputsource::InputSourceService> service)
            : strand_(strand), service_(service) {}

        void onChannelOpenRequest(const aap_protobuf::service::control::message::ChannelOpenRequest &request) override {
            std::cout << "[InputChannel] Recebido ChannelOpenRequest.\n";
            aap_protobuf::service::control::message::ChannelOpenResponse response;
            response.set_status(aap_protobuf::shared::STATUS_SUCCESS);

            auto promise = aasdk::channel::SendPromise::defer(strand_);
            promise->then([]() {
                std::cout << "[InputChannel] ChannelOpenResponse enviado com sucesso.\n";
            }, [](const aasdk::error::Error& e) {
                std::cerr << "[InputChannel] Erro ao enviar ChannelOpenResponse: " << e.what() << "\n";
            });

            service_->sendChannelOpenResponse(response, promise);
        }

        void onKeyBindingRequest(const aap_protobuf::service::media::sink::message::KeyBindingRequest &request) override {
            std::cout << "[InputChannel] onKeyBindingRequest.\n";
            
            aap_protobuf::service::media::sink::message::KeyBindingResponse response;
            response.set_status(aap_protobuf::shared::STATUS_SUCCESS);
            
            auto promise = aasdk::channel::SendPromise::defer(strand_);
            service_->sendKeyBindingResponse(response, promise);
        }

        void onChannelError(const aasdk::error::Error &e) override {
            std::cerr << "[InputChannel] Erro: " << e.what() << "\n";
        }

    private:
        boost::asio::io_context::strand& strand_;
        std::shared_ptr<aasdk::channel::inputsource::InputSourceService> service_;
    };

}
