#include "AndroidAutoFactory.hpp"
#include <aasdk/Messenger/Messenger.hpp>
#include <aasdk/Messenger/Cryptor.hpp>
#include <aasdk/Transport/SSLWrapper.hpp>
#include <aasdk/Messenger/MessageInStream.hpp>
#include <aasdk/Messenger/MessageOutStream.hpp>
#include <iostream>

AndroidAutoEntityImpl::AndroidAutoEntityImpl(boost::asio::io_context& ioContext, aasdk::transport::ITransport::Pointer transport)
    : ioContext_(ioContext), transport_(std::move(transport)) {
    
    std::cout << "[AndroidAutoEntity] Criando Cryptor e Messenger...\n";
    
    auto sslWrapper = std::make_shared<aasdk::transport::SSLWrapper>();
    auto cryptor = std::make_shared<aasdk::messenger::Cryptor>(sslWrapper);
    auto messageInStream = std::make_shared<aasdk::messenger::MessageInStream>(ioContext_, transport_, cryptor);
    auto messageOutStream = std::make_shared<aasdk::messenger::MessageOutStream>(ioContext_, transport_, cryptor);
    
    messenger_ = std::make_shared<aasdk::messenger::Messenger>(ioContext_, messageInStream, messageOutStream);
}

AndroidAutoEntityImpl::~AndroidAutoEntityImpl() {
    stop();
}

void AndroidAutoEntityImpl::start() {
    std::cout << "[AndroidAutoEntity] Inicializando e aguardando chamadas do protocolo...\n";
    
    // O IMessenger nesta versão do AASDK é inicializado pelas streams de entrada/saída (MessageInStream/MessageOutStream)
    // Logo não possui um start() explícito. Em vez disso, a gente começaria o fluxo do ControlChannel.

    // Aqui no futuro vamos registrar os handlers de cada canal:
    // messenger_->registerChannel(...)
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
