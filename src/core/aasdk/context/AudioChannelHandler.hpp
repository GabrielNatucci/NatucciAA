#pragma once

#include <aasdk/Channel/MediaSink/Audio/IAudioMediaSinkServiceEventHandler.hpp>
#include <aasdk/Channel/MediaSink/Audio/AudioMediaSinkService.hpp>
#include <aap_protobuf/service/control/message/ChannelOpenRequest.pb.h>
#include <aap_protobuf/service/control/message/ChannelOpenResponse.pb.h>
#include <aap_protobuf/service/media/shared/message/Setup.pb.h>
#include <aap_protobuf/service/media/shared/message/Config.pb.h>
#include <aap_protobuf/service/media/shared/message/Start.pb.h>
#include <aap_protobuf/service/media/shared/message/Stop.pb.h>
#include <iostream>

namespace natucci {

    class AudioChannelHandler : public aasdk::channel::mediasink::audio::IAudioMediaSinkServiceEventHandler {
    public:
        AudioChannelHandler(boost::asio::io_context::strand& strand, std::shared_ptr<aasdk::channel::mediasink::audio::AudioMediaSinkService> service)
            : strand_(strand), service_(service) {}

        void onChannelOpenRequest(const aap_protobuf::service::control::message::ChannelOpenRequest &request) override {
            std::cout << "[AudioChannel] Recebido ChannelOpenRequest.\n";
            aap_protobuf::service::control::message::ChannelOpenResponse response;
            response.set_status(aap_protobuf::shared::STATUS_SUCCESS);

            auto promise = aasdk::channel::SendPromise::defer(strand_);
            promise->then([]() {
                std::cout << "[AudioChannel] ChannelOpenResponse enviado com sucesso.\n";
            }, [](const aasdk::error::Error& e) {
                std::cerr << "[AudioChannel] Erro ao enviar ChannelOpenResponse: " << e.what() << "\n";
            });

            service_->sendChannelOpenResponse(response, promise);
        }

        void onMediaChannelSetupRequest(const aap_protobuf::service::media::shared::message::Setup &request) override {
            std::cout << "[AudioChannel] onMediaChannelSetupRequest.\n";
            aap_protobuf::service::media::shared::message::Config response;
            
            auto promise = aasdk::channel::SendPromise::defer(strand_);
            promise->then([]() {
                std::cout << "[AudioChannel] Config enviado com sucesso.\n";
            }, [](const aasdk::error::Error& e) {
                std::cerr << "[AudioChannel] Erro ao enviar Config: " << e.what() << "\n";
            });

            service_->sendChannelSetupResponse(response, promise);
        }

        void onMediaChannelStartIndication(const aap_protobuf::service::media::shared::message::Start &indication) override {
            std::cout << "[AudioChannel] onMediaChannelStartIndication.\n";
        }

        void onMediaChannelStopIndication(const aap_protobuf::service::media::shared::message::Stop &indication) override {
            std::cout << "[AudioChannel] onMediaChannelStopIndication.\n";
        }

        void onMediaIndication(const aasdk::common::DataConstBuffer &buffer) override {
            // Audio frames are received here
        }

        void onMediaWithTimestampIndication(aasdk::messenger::Timestamp::ValueType timestamp, const aasdk::common::DataConstBuffer &buffer) override {
            // Audio frames are received here
        }

        void onChannelError(const aasdk::error::Error &e) override {
            std::cerr << "[AudioChannel] Erro: " << e.what() << "\n";
        }

    private:
        boost::asio::io_context::strand& strand_;
        std::shared_ptr<aasdk::channel::mediasink::audio::AudioMediaSinkService> service_;
    };

}
