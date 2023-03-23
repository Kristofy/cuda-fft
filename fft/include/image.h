#pragma once

#include <string>
#include <fstream>
#include <iostream>

//TODO(kristof) bitpack
struct Pixel {
    int r, g, b;
};

struct Image
{
    int width, height;
    int max_rgb;
    std::string format;
    Pixel *pixels;

    Image(const std::string &path);
    ~Image();
    void WriteImage(const std::string &path) const;
    void WriteImageR(const std::string& path) const { WriteImageChanel(path, 0); };
    void WriteImageG(const std::string& path) const { WriteImageChanel(path, 1); };
    void WriteImageB(const std::string& path) const { WriteImageChanel(path, 2); };

private:
    void WriteImageChanel(const std::string &path, int chanel) const;
};
