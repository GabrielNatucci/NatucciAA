#include "AndroidAutoFactory.hpp"
#include "ControlChannelHandler.hpp"
#include <aasdk/Messenger/Messenger.hpp>
#include <aasdk/Messenger/Cryptor.hpp>
#include <aasdk/Transport/SSLWrapper.hpp>
#include <aasdk/Messenger/MessageInStream.hpp>
#include <aasdk/Messenger/MessageOutStream.hpp>
#include <aasdk/Channel/Control/ControlServiceChannel.hpp>
#include <aasdk/Channel/Promise.hpp>
#include <iostream>

AndroidAutoEntityImpl::AndroidAutoEntityImpl(boost::asio::io_context& ioContext, aasdk::transport::ITransport::Pointer transport)
    : ioContext_(ioContext), transport_(std::move(transport)) {
    
    std::cout << "[AndroidAutoEntity] Criando Cryptor e Messenger...\n";
    
    auto sslWrapper = std::make_shared<aasdk::transport::SSLWrapper>();
    auto cryptor = std::make_shared<aasdk::messenger::Cryptor>(sslWrapper);
    auto messageInStream = std::make_shared<aasdk::messenger::MessageInStream>(ioContext_, transport_, cryptor);
    auto messageOutStream = std::make_shared<aasdk::messenger::MessageOutStream>(ioContext_, transport_, cryptor);
    
    messenger_ = std::make_shared<aasdk::messenger::Messenger>(ioContext_, messageInStream, messageOutStream);
    strand_ = std::make_shared<boost::asio::io_context::strand>(ioContext_);
}

AndroidAutoEntityImpl::~AndroidAutoEntityImpl() {
    stop();
}

void AndroidAutoEntityImpl::start() {
    std::cout << "[AndroidAutoEntity] Inicializando Canal de Controle (Handshake)...\n";
    
    controlChannel_ = std::make_shared<aasdk::channel::control::ControlServiceChannel>(*strand_, messenger_);
    controlHandler_ = std::make_shared<natucci::ControlChannelHandler>(controlChannel_);
    
    // 1. Começa a escutar o Canal 0
    controlChannel_->receive(controlHandler_);

    // 2. Envia a solicitação de versão para o celular iniciar o protocolo
    std::cout << "[AndroidAutoEntity] Enviando Version Request (1.6)...\n";
    auto promise = aasdk::channel::SendPromise::defer(*strand_);
    promise->then([]() {
        std::cout << "[AndroidAutoEntity] Version Request enviado com sucesso!\n";
    }, [](const aasdk::error::Error& e) {
        std::cerr << "[AndroidAutoEntity] Erro ao enviar Version Request: " << e.what() << "\n";
    });
    
    controlChannel_->sendVersionRequest(promise);
}

void AndroidAutoEntityImpl::stop() {
    std::cout << "[AndroidAutoEntity] Parando entidade do Android Auto...\n";
    // se o messenger já tiver sido iniciado:
    // messenger_->stop();
}


AndroidAutoFactory::AndroidAutoFactory(boost::asio::io_context& ioContext)
    : ioContext_(ioContext) {
}

std::shared_ptr<AndroidAutoEntity> AndroidAutoFactory::create(aasdk::transport::ITransport::Pointer transport) {
    std::cout << "[AndroidAutoFactory] Criando nova entidade para o Transport conectado.\n";
    return std::make_shared<AndroidAutoEntityImpl>(ioContext_, std::move(transport));
}
