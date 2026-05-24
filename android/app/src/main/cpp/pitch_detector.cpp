#include "pitch_detector.h"

#include <algorithm>
#include <cmath>
#include <iterator>

namespace tuna {
namespace {

constexpr float kYinThreshold = 0.12f;
constexpr float kFallbackClarity = 0.55f;
constexpr float kMinRms = 0.006f;
constexpr float kPi = 3.14159265358979323846f;

}  // namespace

YinFftPitchDetector::YinFftPitchDetector(
    std::size_t window_size,
    int sample_rate,
    float min_hz,
    float max_hz)
    : window_size_(window_size),
      fft_size_(next_power_of_two(window_size * 2)),
      sample_rate_(sample_rate),
      min_hz_(min_hz),
      max_hz_(max_hz),
      min_tau_(std::max<std::size_t>(2, static_cast<std::size_t>(sample_rate_ / max_hz_))),
      max_tau_(std::min<std::size_t>(
          window_size_ - 2,
          static_cast<std::size_t>(sample_rate_ / min_hz_))),
      window_(window_size_),
      prefix_squares_(window_size_ + 1),
      difference_(max_tau_ + 1),
      cumulative_mean_(max_tau_ + 1),
      fft_buffer_(fft_size_) {}

PitchResult YinFftPitchDetector::detect(const float* samples, std::size_t sample_count) {
    if (samples == nullptr || sample_count < window_size_ || max_tau_ <= min_tau_) {
        return {};
    }

    float mean = 0.0f;
    for (std::size_t i = 0; i < window_size_; ++i) {
        mean += samples[i];
    }
    mean /= static_cast<float>(window_size_);

    float energy = 0.0f;
    prefix_squares_[0] = 0.0f;
    for (std::size_t i = 0; i < window_size_; ++i) {
        const float sample = samples[i] - mean;
        window_[i] = sample;
        energy += sample * sample;
        prefix_squares_[i + 1] = prefix_squares_[i] + sample * sample;
    }

    const float rms = std::sqrt(energy / static_cast<float>(window_size_));
    if (rms < kMinRms) {
        return {};
    }

    std::fill(fft_buffer_.begin(), fft_buffer_.end(), std::complex<float>(0.0f, 0.0f));
    for (std::size_t i = 0; i < window_size_; ++i) {
        fft_buffer_[i] = std::complex<float>(window_[i], 0.0f);
    }

    fft(fft_buffer_, false);
    for (auto& value : fft_buffer_) {
        value *= std::conj(value);
    }
    fft(fft_buffer_, true);

    cumulative_mean_[0] = 1.0f;
    float running_sum = 0.0f;
    for (std::size_t tau = 1; tau <= max_tau_; ++tau) {
        const float acf = fft_buffer_[tau].real();
        const float energy_at_tau =
            prefix_squares_[window_size_ - tau] + (prefix_squares_[window_size_] - prefix_squares_[tau]);
        difference_[tau] = std::max(0.0f, energy_at_tau - (2.0f * acf));
        running_sum += difference_[tau];
        cumulative_mean_[tau] =
            running_sum > 0.0f ? (difference_[tau] * static_cast<float>(tau) / running_sum) : 1.0f;
    }

    std::size_t tau_estimate = 0;
    for (std::size_t tau = min_tau_; tau <= max_tau_; ++tau) {
        if (cumulative_mean_[tau] < kYinThreshold) {
            while (tau + 1 <= max_tau_ && cumulative_mean_[tau + 1] < cumulative_mean_[tau]) {
                ++tau;
            }
            tau_estimate = tau;
            break;
        }
    }

    if (tau_estimate == 0) {
        auto best = std::min_element(
            cumulative_mean_.begin() + static_cast<std::ptrdiff_t>(min_tau_),
            cumulative_mean_.begin() + static_cast<std::ptrdiff_t>(max_tau_ + 1));
        const float clarity = 1.0f - *best;
        if (clarity < kFallbackClarity) {
            return {};
        }
        tau_estimate = static_cast<std::size_t>(std::distance(cumulative_mean_.begin(), best));
    }

    float better_tau = static_cast<float>(tau_estimate);
    if (tau_estimate > 0 && tau_estimate < max_tau_) {
        const float left = cumulative_mean_[tau_estimate - 1];
        const float center = cumulative_mean_[tau_estimate];
        const float right = cumulative_mean_[tau_estimate + 1];
        const float denominator = left - (2.0f * center) + right;
        if (std::abs(denominator) > 1.0e-12f) {
            better_tau += 0.5f * (left - right) / denominator;
        }
    }

    const float frequency = static_cast<float>(sample_rate_) / better_tau;
    if (frequency < min_hz_ || frequency > max_hz_ || !std::isfinite(frequency)) {
        return {};
    }

    return {frequency, std::clamp(1.0f - cumulative_mean_[tau_estimate], 0.0f, 1.0f)};
}

void YinFftPitchDetector::fft(std::vector<std::complex<float>>& values, bool inverse) {
    const std::size_t n = values.size();
    for (std::size_t i = 1, j = 0; i < n; ++i) {
        std::size_t bit = n >> 1U;
        for (; (j & bit) != 0; bit >>= 1U) {
            j ^= bit;
        }
        j ^= bit;
        if (i < j) {
            std::swap(values[i], values[j]);
        }
    }

    for (std::size_t len = 2; len <= n; len <<= 1U) {
        const float angle =
            (inverse ? 2.0f : -2.0f) * kPi / static_cast<float>(len);
        const std::complex<float> w_len(std::cos(angle), std::sin(angle));
        for (std::size_t i = 0; i < n; i += len) {
            std::complex<float> w(1.0f, 0.0f);
            for (std::size_t j = 0; j < len / 2; ++j) {
                const std::complex<float> u = values[i + j];
                const std::complex<float> v = values[i + j + len / 2] * w;
                values[i + j] = u + v;
                values[i + j + len / 2] = u - v;
                w *= w_len;
            }
        }
    }

    if (inverse) {
        const float scale = 1.0f / static_cast<float>(n);
        for (auto& value : values) {
            value *= scale;
        }
    }
}

std::size_t YinFftPitchDetector::next_power_of_two(std::size_t value) {
    std::size_t result = 1;
    while (result < value) {
        result <<= 1U;
    }
    return result;
}

}  // namespace tuna
