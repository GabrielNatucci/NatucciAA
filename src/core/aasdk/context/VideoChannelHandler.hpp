#pragma once

#include <aasdk/Channel/MediaSink/Video/IVideoMediaSinkServiceEventHandler.hpp>
#include <aasdk/Channel/MediaSink/Video/VideoMediaSinkService.hpp>
#include <aap_protobuf/service/control/message/ChannelOpenRequest.pb.h>
#include <aap_protobuf/service/control/message/ChannelOpenResponse.pb.h>
#include <aap_protobuf/service/media/shared/message/Setup.pb.h>
#include <aap_protobuf/service/media/shared/message/Config.pb.h>
#include <aap_protobuf/service/media/shared/message/Start.pb.h>
#include <aap_protobuf/service/media/shared/message/Stop.pb.h>
#include <aap_protobuf/service/media/video/message/VideoFocusRequestNotification.pb.h>
#include <aap_protobuf/service/media/video/message/VideoFocusNotification.pb.h>
#include <aap_protobuf/service/media/video/message/VideoFocusMode.pb.h>
#include <iostream>

namespace natucci {

    class VideoChannelHandler : public aasdk::channel::mediasink::video::IVideoMediaSinkServiceEventHandler {
    public:
        VideoChannelHandler(boost::asio::io_context::strand& strand, std::shared_ptr<aasdk::channel::mediasink::video::VideoMediaSinkService> service)
            : strand_(strand), service_(service) {}

        void onChannelOpenRequest(const aap_protobuf::service::control::message::ChannelOpenRequest &request) override {
            std::cout << "[VideoChannel] Recebido ChannelOpenRequest.\n";
            aap_protobuf::service::control::message::ChannelOpenResponse response;
            response.set_status(aap_protobuf::shared::STATUS_SUCCESS);

            auto promise = aasdk::channel::SendPromise::defer(strand_);
            promise->then([]() {
                std::cout << "[VideoChannel] ChannelOpenResponse enviado com sucesso.\n";
            }, [](const aasdk::error::Error& e) {
                std::cerr << "[VideoChannel] Erro ao enviar ChannelOpenResponse: " << e.what() << "\n";
            });

            service_->sendChannelOpenResponse(response, promise);
        }

        void onMediaChannelSetupRequest(const aap_protobuf::service::media::shared::message::Setup &request) override {
            std::cout << "[VideoChannel] onMediaChannelSetupRequest.\n";
            aap_protobuf::service::media::shared::message::Config response;
            
            auto promise = aasdk::channel::SendPromise::defer(strand_);
            promise->then([]() {
                std::cout << "[VideoChannel] Config enviado com sucesso.\n";
            }, [](const aasdk::error::Error& e) {
                std::cerr << "[VideoChannel] Erro ao enviar Config: " << e.what() << "\n";
            });

            service_->sendChannelSetupResponse(response, promise);
        }

        void onMediaChannelStartIndication(const aap_protobuf::service::media::shared::message::Start &indication) override {
            std::cout << "[VideoChannel] onMediaChannelStartIndication.\n";
        }

        void onMediaChannelStopIndication(const aap_protobuf::service::media::shared::message::Stop &indication) override {
            std::cout << "[VideoChannel] onMediaChannelStopIndication.\n";
        }

        void onMediaIndication(const aasdk::common::DataConstBuffer &buffer) override {
            // Ignorar print por byte, senao enche o console
        }

        void onMediaWithTimestampIndication(aasdk::messenger::Timestamp::ValueType timestamp, const aasdk::common::DataConstBuffer &buffer) override {
            // Ignorar
        }

        void onVideoFocusRequest(const aap_protobuf::service::media::video::message::VideoFocusRequestNotification &request) override {
            std::cout << "[VideoChannel] onVideoFocusRequest.\n";
            
            aap_protobuf::service::media::video::message::VideoFocusNotification indication;
            indication.set_focus(aap_protobuf::service::media::video::message::VIDEO_FOCUS_PROJECTED);
            
            auto promise = aasdk::channel::SendPromise::defer(strand_);
            service_->sendVideoFocusIndication(indication, promise);
        }

        void onChannelError(const aasdk::error::Error &e) override {
            std::cerr << "[VideoChannel] Erro: " << e.what() << "\n";
        }

    private:
        boost::asio::io_context::strand& strand_;
        std::shared_ptr<aasdk::channel::mediasink::video::VideoMediaSinkService> service_;
    };

}
