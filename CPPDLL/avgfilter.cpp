#include "pch.h"
#include <vector>
#include <algorithm>

extern "C" __declspec(dllexport) void AVGFILTER(unsigned char* pixelData, unsigned char* outputData, int width, int startY, int endY, int imageHeight) {
    const int maskSize = 3; // Maska 3x3
    const int halfMask = maskSize / 2;
    const float maskValue = 1.0f / 9.0f; // Ka¿dy piksel w masce ma wagê 1/9

    for (int y = startY; y < endY; ++y) {
        for (int x = 0; x < width; ++x) {
            float sumBlue = 0.0f, sumGreen = 0.0f, sumRed = 0.0f;

            for (int dy = -halfMask; dy <= halfMask; ++dy) {
                for (int dx = -halfMask; dx <= halfMask; ++dx) {
                    int nx = x + dx;
                    int ny = y + dy;

                    // Upewniamy siê, ¿e wspó³rzêdne mieszcz¹ siê w obrazie
                    if (nx >= 0 && nx < width && ny >= 0 && ny < imageHeight) {
                        int index = (ny * width + nx) * 3; // Indeks dla RGB
                        sumBlue += pixelData[index] * maskValue;
                        sumGreen += pixelData[index + 1] * maskValue;
                        sumRed += pixelData[index + 2] * maskValue;
                    }
                }
            }

            // Zapisujemy wynik do wyjœciowego obrazu
            int index = (y * width + x) * 3;
            outputData[index] = static_cast<unsigned char>(std::clamp(sumBlue, 0.0f, 255.0f));
            outputData[index + 1] = static_cast<unsigned char>(std::clamp(sumGreen, 0.0f, 255.0f));
            outputData[index + 2] = static_cast<unsigned char>(std::clamp(sumRed, 0.0f, 255.0f));
        }
    }
}
