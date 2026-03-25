#pragma once

#include <aap_protobuf/shared/MessageStatus.pb.h>
#include <aap_protobuf/service/control/message/ByeByeRequest.pb.h>
#include <aasdk/Channel/Control/IControlServiceChannelEventHandler.hpp>
#include <aasdk/Channel/Control/IControlServiceChannel.hpp>
#include <memory>

namespace natucci {

    class ControlChannelHandler : public aasdk::channel::control::IControlServiceChannelEventHandler, 
                                 public std::enable_shared_from_this<ControlChannelHandler> {
    public:
        typedef std::shared_ptr<ControlChannelHandler> Pointer;

        ControlChannelHandler(aasdk::channel::control::IControlServiceChannel::Pointer channel);
        
        // IControlServiceChannelEventHandler implementation
        void onVersionResponse(uint16_t majorCode, uint16_t minorCode, aap_protobuf::shared::MessageStatus status) override;
        void onHandshake(const aasdk::common::DataConstBuffer &payload) override;
        void onServiceDiscoveryRequest(const aap_protobuf::service::control::message::ServiceDiscoveryRequest &request) override;
        void onAudioFocusRequest(const aap_protobuf::service::control::message::AudioFocusRequest &request) override;
        void onByeByeRequest(const aap_protobuf::service::control::message::ByeByeRequest &request) override;
        void onByeByeResponse(const aap_protobuf::service::control::message::ByeByeResponse &response) override;
        void onBatteryStatusNotification(const aap_protobuf::service::control::message::BatteryStatusNotification &notification) override;
        void onNavigationFocusRequest(const aap_protobuf::service::control::message::NavFocusRequestNotification &request) override;
        void onVoiceSessionRequest(const aap_protobuf::service::control::message::VoiceSessionNotification &request) override;
        void onPingRequest(const aap_protobuf::service::control::message::PingRequest &request) override;
        void onPingResponse(const aap_protobuf::service::control::message::PingResponse &response) override;
        void onChannelError(const aasdk::error::Error &e) override;

    private:
        aasdk::channel::control::IControlServiceChannel::Pointer channel_;
    };

}
