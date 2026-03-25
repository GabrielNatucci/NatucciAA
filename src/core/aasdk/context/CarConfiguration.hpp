#pragma once
#include <aap_protobuf/service/control/message/ServiceDiscoveryResponse.pb.h>

namespace natucci {
    class CarConfiguration {
    public:
        static aap_protobuf::service::control::message::ServiceDiscoveryResponse createResponse();
    };
}
