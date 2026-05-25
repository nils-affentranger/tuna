#include <jni.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include <android/log.h>
#include <oboe/Oboe.h>

#include "pitch_detector.h"

namespace {

constexpr const char* kLogTag = "TunaAudio";
constexpr std::size_t kWindowSize = 4096;
constexpr float kMinPitchHz = 40.0f;
constexpr float kMaxPitchHz = 1200.0f;

class TunerAudioEngine : public oboe::AudioStreamDataCallback {
public:
    ~TunerAudioEngine() override { stop(); }

    bool start() {
        std::lock_guard<std::mutex> lock(lifecycle_mutex_);
        stop_locked();

        oboe::AudioStreamBuilder builder;
        builder.setDirection(oboe::Direction::Input);
        builder.setPerformanceMode(oboe::PerformanceMode::LowLatency);
        builder.setSharingMode(oboe::SharingMode::Exclusive);
        builder.setFormat(oboe::AudioFormat::Float);
        builder.setChannelCount(oboe::ChannelCount::Mono);
        builder.setInputPreset(oboe::InputPreset::VoiceRecognition);
        builder.setDataCallback(this);

        oboe::Result result = builder.openStream(&stream_);
        if (result != oboe::Result::OK) {
            builder.setSharingMode(oboe::SharingMode::Shared);
            result = builder.openStream(&stream_);
        }
        if (result != oboe::Result::OK || stream_ == nullptr) {
            set_error("Unable to open Oboe input stream: " + std::string(oboe::convertToText(result)));
            return false;
        }

        sample_rate_ = stream_->getSampleRate() > 0 ? stream_->getSampleRate() : 48000;
        channel_count_ = std::max(1, stream_->getChannelCount());
        const std::size_t ring_capacity =
            std::max<std::size_t>(static_cast<std::size_t>(sample_rate_) * 2, kWindowSize * 4);

        ring_.assign(ring_capacity, 0.0f);
        analysis_buffer_.assign(kWindowSize, 0.0f);
        detector_ = std::make_unique<tuna::YinFftPitchDetector>(
            kWindowSize,
            sample_rate_,
            kMinPitchHz,
            kMaxPitchHz);
        write_index_.store(0, std::memory_order_release);
        last_analysis_index_ = 0;
        latest_hz_.store(0.0f, std::memory_order_release);
        latest_clarity_.store(0.0f, std::memory_order_release);
        running_.store(true, std::memory_order_release);

        result = stream_->requestStart();
        if (result != oboe::Result::OK) {
            set_error("Unable to start Oboe input stream: " + std::string(oboe::convertToText(result)));
            stop_locked();
            return false;
        }

        worker_ = std::thread(&TunerAudioEngine::analysis_loop, this);
        set_error("");
        __android_log_print(ANDROID_LOG_INFO, kLogTag, "Started Oboe input at %d Hz", sample_rate_);
        return true;
    }

    void stop() {
        std::lock_guard<std::mutex> lock(lifecycle_mutex_);
        stop_locked();
    }

    std::pair<float, float> latest_pitch() const {
        return {
            latest_hz_.load(std::memory_order_acquire),
            latest_clarity_.load(std::memory_order_acquire),
        };
    }

    std::string last_error() const {
        std::lock_guard<std::mutex> lock(error_mutex_);
        return last_error_;
    }

    oboe::DataCallbackResult onAudioReady(
        oboe::AudioStream* audio_stream,
        void* audio_data,
        int32_t num_frames) override {
        if (!running_.load(std::memory_order_acquire) || audio_data == nullptr || ring_.empty()) {
            return oboe::DataCallbackResult::Continue;
        }

        const auto* input = static_cast<const float*>(audio_data);
        const int channel_count = std::max(1, audio_stream->getChannelCount());
        const std::size_t capacity = ring_.size();
        uint64_t index = write_index_.load(std::memory_order_relaxed);

        for (int32_t frame = 0; frame < num_frames; ++frame) {
            ring_[index % capacity] = input[frame * channel_count];
            ++index;
        }
        write_index_.store(index, std::memory_order_release);
        return oboe::DataCallbackResult::Continue;
    }

private:
    void stop_locked() {
        running_.store(false, std::memory_order_release);

        if (stream_ != nullptr) {
            stream_->requestStop();
            stream_->close();
            stream_ = nullptr;
        }

        if (worker_.joinable()) {
            worker_.join();
        }
    }

    void analysis_loop() {
        const uint64_t hop_size = sample_rate_ >= 44100 ? 512 : 256;
        while (running_.load(std::memory_order_acquire)) {
            const uint64_t write_index = write_index_.load(std::memory_order_acquire);
            if (write_index >= kWindowSize && write_index - last_analysis_index_ >= hop_size) {
                copy_latest_window(write_index);
                const tuna::PitchResult pitch = detector_->detect(analysis_buffer_.data(), analysis_buffer_.size());
                latest_hz_.store(pitch.frequency_hz, std::memory_order_release);
                latest_clarity_.store(pitch.clarity, std::memory_order_release);
                last_analysis_index_ = write_index;
            }
            std::this_thread::sleep_for(std::chrono::milliseconds(4));
        }
    }

    void copy_latest_window(uint64_t write_index) {
        const uint64_t start = write_index - kWindowSize;
        const std::size_t capacity = ring_.size();
        for (std::size_t i = 0; i < kWindowSize; ++i) {
            analysis_buffer_[i] = ring_[(start + i) % capacity];
        }
    }

    void set_error(std::string error) {
        std::lock_guard<std::mutex> lock(error_mutex_);
        last_error_ = std::move(error);
    }

    mutable std::mutex lifecycle_mutex_;
    mutable std::mutex error_mutex_;
    std::string last_error_;
    oboe::AudioStream* stream_ = nullptr;
    std::thread worker_;
    std::atomic<bool> running_{false};
    std::atomic<uint64_t> write_index_{0};
    uint64_t last_analysis_index_ = 0;
    int sample_rate_ = 48000;
    int channel_count_ = 1;
    std::vector<float> ring_;
    std::vector<float> analysis_buffer_;
    std::unique_ptr<tuna::YinFftPitchDetector> detector_;
    std::atomic<float> latest_hz_{0.0f};
    std::atomic<float> latest_clarity_{0.0f};
};

TunerAudioEngine g_engine;

}  // namespace

extern "C" JNIEXPORT jboolean JNICALL
Java_com_example_tuna_MainActivity_nativeStartTuner(JNIEnv*, jobject) {
    return g_engine.start() ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT void JNICALL
Java_com_example_tuna_MainActivity_nativeStopTuner(JNIEnv*, jobject) {
    g_engine.stop();
}

extern "C" JNIEXPORT jfloatArray JNICALL
Java_com_example_tuna_MainActivity_nativeGetLatestPitch(JNIEnv* env, jobject) {
    const auto [frequency, clarity] = g_engine.latest_pitch();
    jfloat values[2] = {frequency, clarity};
    jfloatArray result = env->NewFloatArray(2);
    env->SetFloatArrayRegion(result, 0, 2, values);
    return result;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_tuna_MainActivity_nativeGetLastError(JNIEnv* env, jobject) {
    return env->NewStringUTF(g_engine.last_error().c_str());
}
