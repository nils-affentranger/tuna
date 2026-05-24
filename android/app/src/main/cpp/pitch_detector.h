#pragma once

#include <complex>
#include <cstddef>
#include <vector>

namespace tuna {

struct PitchResult {
    float frequency_hz = 0.0f;
    float clarity = 0.0f;
};

class YinFftPitchDetector {
public:
    YinFftPitchDetector(std::size_t window_size, int sample_rate, float min_hz, float max_hz);

    PitchResult detect(const float* samples, std::size_t sample_count);

    std::size_t window_size() const { return window_size_; }

private:
    void fft(std::vector<std::complex<float>>& values, bool inverse);
    static std::size_t next_power_of_two(std::size_t value);

    std::size_t window_size_;
    std::size_t fft_size_;
    int sample_rate_;
    float min_hz_;
    float max_hz_;
    std::size_t min_tau_;
    std::size_t max_tau_;
    std::vector<float> window_;
    std::vector<float> prefix_squares_;
    std::vector<float> difference_;
    std::vector<float> cumulative_mean_;
    std::vector<std::complex<float>> fft_buffer_;
};

}  // namespace tuna
