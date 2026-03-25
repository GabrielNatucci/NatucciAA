#include "ControlChannelHandler.hpp"
#include "CarConfiguration.hpp"
#include <iostream>

namespace natucci {

    ControlChannelHandler::ControlChannelHandler(aasdk::channel::control::IControlServiceChannel::Pointer channel)
        : channel_(std::move(channel)) {
    }

    void ControlChannelHandler::onVersionResponse(uint16_t majorCode, uint16_t minorCode, aap_protobuf::shared::MessageStatus status) {
        std::cout << "[ControlChannel] Recebeu Versão: " << majorCode << "." << minorCode << " Status: " << status << "\n";
    }

    void ControlChannelHandler::onHandshake(const aasdk::common::DataConstBuffer &payload) {
        std::cout << "[ControlChannel] Recebeu Handshake (" << payload.size << " bytes)\n";
    }

    void ControlChannelHandler::onServiceDiscoveryRequest(const aap_protobuf::service::control::message::ServiceDiscoveryRequest &request) {
        std::cout << "[ControlChannel] Discovery Request recebida! Respondendo com configuração do carro...\n";
        
        auto response = CarConfiguration::createResponse();
        channel_->sendServiceDiscoveryResponse(response, nullptr);
    }

    void ControlChannelHandler::onAudioFocusRequest(const aap_protobuf::service::control::message::AudioFocusRequest &request) {
        std::cout << "[ControlChannel] Audio Focus Request recebida.\n";
    }

    void ControlChannelHandler::onByeByeRequest(const aap_protobuf::service::control::message::ByeByeRequest &request) {
        std::cout << "[ControlChannel] ByeBye Request recebida.\n";
    }

    void ControlChannelHandler::onByeByeResponse(const aap_protobuf::service::control::message::ByeByeResponse &response) {
        std::cout << "[ControlChannel] ByeBye Response recebida.\n";
    }

    void ControlChannelHandler::onBatteryStatusNotification(const aap_protobuf::service::control::message::BatteryStatusNotification &notification) {
        // Ignorar por enquanto
    }

    void ControlChannelHandler::onNavigationFocusRequest(const aap_protobuf::service::control::message::NavFocusRequestNotification &request) {
        std::cout << "[ControlChannel] Nav Focus Request recebida.\n";
    }

    void ControlChannelHandler::onVoiceSessionRequest(const aap_protobuf::service::control::message::VoiceSessionNotification &request) {
        std::cout << "[ControlChannel] Voice Session Request recebida.\n";
    }

    void ControlChannelHandler::onPingRequest(const aap_protobuf::service::control::message::PingRequest &request) {
        // Enviar pong de volta
        aap_protobuf::service::control::message::PingResponse response;
        response.set_timestamp(request.timestamp());
        channel_->sendPingResponse(response, nullptr);
    }

    void ControlChannelHandler::onPingResponse(const aap_protobuf::service::control::message::PingResponse &response) {
        // Ignorar
    }

    void ControlChannelHandler::onChannelError(const aasdk::error::Error &e) {
        std::cerr << "[ControlChannel] Erro: " << e.what() << "\n";
    }

}
