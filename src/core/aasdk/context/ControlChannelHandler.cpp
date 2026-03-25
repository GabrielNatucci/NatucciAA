#include "ControlChannelHandler.hpp"
#include "CarConfiguration.hpp"
#include <aasdk/Channel/Promise.hpp>
#include <aap_protobuf/service/control/message/AuthResponse.pb.h>
#include <iostream>

namespace natucci {

    ControlChannelHandler::ControlChannelHandler(aasdk::channel::control::IControlServiceChannel::Pointer channel,
                                                 aasdk::messenger::ICryptor::Pointer cryptor,
                                                 boost::asio::io_context::strand& strand)
        : channel_(std::move(channel)), cryptor_(std::move(cryptor)), strand_(strand) {
    }

    void ControlChannelHandler::onVersionResponse(uint16_t majorCode, uint16_t minorCode, aap_protobuf::shared::MessageStatus status) {
        std::cout << "[ControlChannel] Recebeu Versão: " << majorCode << "." << minorCode << " Status: " << status << "\n";
        
        if (status == 0) {
            std::cout << "[ControlChannel] Versão aceita. Iniciando o Cryptor e o Handshake SSL...\n";
            try {
                cryptor_->init();
                isCryptorInitialized_ = true;
                
                bool complete = cryptor_->doHandshake();
                auto payload = cryptor_->readHandshakeBuffer();
                
                auto promise = aasdk::channel::SendPromise::defer(strand_);
                promise->then([]() {
                    std::cout << "[ControlChannel] Primeiro pacote de Handshake enviado!\n";
                }, [](const aasdk::error::Error& e) {
                    std::cerr << "[ControlChannel] Erro ao enviar pacote de Handshake: " << e.what() << "\n";
                });
                channel_->sendHandshake(std::move(payload), promise);
                
                if (complete) {
                    std::cout << "[ControlChannel] Handshake SSL Completo logo de cara!\n";
                }
            } catch (const std::exception& e) {
                std::cerr << "[ControlChannel] Exceção na inicialização do Cryptor: " << e.what() << "\n";
            }
        } else {
            std::cerr << "[ControlChannel] Celular rejeitou a versão (Status: " << status << ")\n";
        }

        // Mantém o canal ouvindo o próximo pacote
        channel_->receive(shared_from_this());
    }

    void ControlChannelHandler::onHandshake(const aasdk::common::DataConstBuffer &payload) {
        std::cout << "[ControlChannel] Recebeu Handshake (" << payload.size << " bytes). Processando...\n";
        
        if (!isCryptorInitialized_) {
            std::cout << "[ControlChannel] Ignorando payload de Handshake porque o Cryptor ainda não foi inicializado.\n";
            channel_->receive(shared_from_this());
            return;
        }

        try {
            cryptor_->writeHandshakeBuffer(payload);

            if (!cryptor_->doHandshake()) {
                auto responsePayload = cryptor_->readHandshakeBuffer();
                
                auto promise = aasdk::channel::SendPromise::defer(strand_);
                promise->then([]() {
                    std::cout << "[ControlChannel] Resposta de Handshake enviada.\n";
                }, [](const aasdk::error::Error& e) {
                    std::cerr << "[ControlChannel] Erro ao responder Handshake: " << e.what() << "\n";
                });
                channel_->sendHandshake(std::move(responsePayload), promise);
            } else {
                std::cout << "[ControlChannel] Handshake SSL Concluído com Sucesso! Enviando AuthComplete...\n";
                aap_protobuf::service::control::message::AuthResponse authResponse;
                authResponse.set_status(0); // OK
                
                auto promise = aasdk::channel::SendPromise::defer(strand_);
                promise->then([]() {
                    std::cout << "[ControlChannel] AuthComplete enviado com sucesso. Aguardando Service Discovery...\n";
                }, [](const aasdk::error::Error& e) {
                    std::cerr << "[ControlChannel] Erro ao enviar AuthComplete: " << e.what() << "\n";
                });
                channel_->sendAuthComplete(authResponse, promise);
            }
        } catch (const aasdk::error::Error& e) {
            std::cerr << "[ControlChannel] Erro AASDK no processamento do Handshake: " << e.what() << "\n";
        } catch (const std::exception& e) {
            std::cerr << "[ControlChannel] Exceção genérica no Handshake: " << e.what() << "\n";
        }

        // Mantém o canal ouvindo o próximo pacote
        channel_->receive(shared_from_this());
    }

    void ControlChannelHandler::onServiceDiscoveryRequest(const aap_protobuf::service::control::message::ServiceDiscoveryRequest &request) {
        std::cout << "[ControlChannel] Discovery Request recebida! Respondendo com configuração do carro...\n";
        
        auto response = CarConfiguration::createResponse();
        auto promise = aasdk::channel::SendPromise::defer(strand_);
        promise->then([]() {
            std::cout << "[ControlChannel] Configuração do carro enviada com sucesso! O celular deve liberar os canais agora.\n";
        }, [](const aasdk::error::Error& e) {
            std::cerr << "[ControlChannel] Erro ao enviar Discovery Response: " << e.what() << "\n";
        });
        
        channel_->sendServiceDiscoveryResponse(response, promise);

        // Mantém o canal ouvindo (para Ping, Shutdown, etc.)
        channel_->receive(shared_from_this());
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
