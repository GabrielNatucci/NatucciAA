#include "CarConfiguration.hpp"
#include <aap_protobuf/service/Service.pb.h>
#include <aap_protobuf/service/media/sink/MediaSinkService.pb.h>
#include <aap_protobuf/service/media/sink/message/VideoConfiguration.pb.h>
#include <aap_protobuf/service/media/sink/message/VideoCodecResolutionType.pb.h>
#include <aap_protobuf/service/media/sink/message/VideoFrameRateType.pb.h>
#include <aap_protobuf/service/media/shared/message/MediaCodecType.pb.h>
#include <aap_protobuf/service/media/sink/message/AudioStreamType.pb.h>
#include <aap_protobuf/service/inputsource/InputSourceService.pb.h>
#include <aap_protobuf/service/inputsource/message/TouchScreenType.pb.h>
#include <aap_protobuf/service/control/message/ServiceDiscoveryResponse.pb.h>
#include <aap_protobuf/service/control/message/HeadUnitInfo.pb.h>

namespace natucci {

    aap_protobuf::service::control::message::ServiceDiscoveryResponse CarConfiguration::createResponse() {
        aap_protobuf::service::control::message::ServiceDiscoveryResponse response;
        
        // HeadUnit Info
        auto* huInfo = response.mutable_headunit_info();
        huInfo->set_make("Natucci");
        huInfo->set_model("AA-Player");
        huInfo->set_head_unit_software_build("1.0");
        huInfo->set_head_unit_software_version("1.0");

        // Vídeo Service
        auto* videoService = response.add_channels();
        videoService->set_id(3); // Protocol ID for Video
        auto* videoSink = videoService->mutable_media_sink_service();
        auto* videoConfig = videoSink->add_video_configs();
        videoConfig->set_codec_resolution(aap_protobuf::service::media::sink::message::VIDEO_1280x720);
        videoConfig->set_frame_rate(aap_protobuf::service::media::sink::message::VIDEO_FPS_60);
        videoConfig->set_video_codec_type(aap_protobuf::service::media::shared::message::MEDIA_CODEC_VIDEO_H264_BP);

        // Áudio Service (Media)
        auto* audioMedia = response.add_channels();
        audioMedia->set_id(4);
        auto* audioSinkMedia = audioMedia->mutable_media_sink_service();
        audioSinkMedia->set_audio_type(aap_protobuf::service::media::sink::message::AUDIO_STREAM_MEDIA);
        
        // Input Service (Touch)
        auto* inputService = response.add_channels();
        inputService->set_id(2);
        auto* inputSource = inputService->mutable_input_source_service();
        auto* touchScreen = inputSource->add_touchscreen();
        touchScreen->set_width(1280);
        touchScreen->set_height(720);
        touchScreen->set_type(aap_protobuf::service::inputsource::message::CAPACITIVE);
        
        return response;
    }

}
