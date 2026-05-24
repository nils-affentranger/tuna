#include <cmath>
#include <iostream>
#include <vector>

#include "../../main/cpp/pitch_detector.h"

namespace {

constexpr float kPi = 3.14159265358979323846f;

bool detects(float expected_hz) {
    constexpr int sample_rate = 48000;
    constexpr std::size_t window_size = 4096;
    std::vector<float> samples(window_size);

    for (std::size_t i = 0; i < samples.size(); ++i) {
        const float t = static_cast<float>(i) / static_cast<float>(sample_rate);
        samples[i] = 0.65f * std::sin(2.0f * kPi * expected_hz * t) +
            0.10f * std::sin(2.0f * kPi * expected_hz * 2.0f * t);
    }

    tuna::YinFftPitchDetector detector(window_size, sample_rate, 40.0f, 1200.0f);
    const tuna::PitchResult pitch = detector.detect(samples.data(), samples.size());
    const float cents = 1200.0f * std::log2(pitch.frequency_hz / expected_hz);
    std::cout << "expected=" << expected_hz << " detected=" << pitch.frequency_hz
              << " clarity=" << pitch.clarity << " cents=" << cents << '\n';
    return std::abs(cents) < 5.0f && pitch.clarity > 0.80f;
}

}  // namespace

int main() {
    if (!detects(82.4069f) || !detects(110.0f) || !detects(440.0f)) {
        return 1;
    }
    return 0;
}
