#include "image.h"

Image::Image(const std::string &path)
{
    std::ifstream fin_img(path);
    if(!fin_img.is_open()) {
        std::cerr << "Error opening image: " << path << '\n';
        std::exit(1);
    }

    fin_img >> this->format;
    fin_img >> this->width >> this->height;
    fin_img >> this->max_rgb;

    if(this->max_rgb != 255){
        std::cerr << "non 255 RGB values are not supported";
        std::exit(1);
    }

    this->pixels = new Pixel [this->height * this->width];
    for (int i = 0; i < this->height; i++)
    {
        for (int j = 0; j < this->width; j++)
        {
            const int index = i * this->width + j;
            fin_img >> this->pixels[index].r >> this->pixels[index].g >> this->pixels[index].b;
        }
    }
}

Image::~Image(){
    delete[] this->pixels;
}

void Image::WriteImage(const std::string &path) const
{
    std::ofstream fout_img(path + ".ppm");
    if (!fout_img.is_open())
    {
        std::cerr << "Error opening image: " << path << '\n';
        std::exit(1);
    }

    fout_img << this->format << '\n';
    fout_img << this->width << ' ' << this->height << '\n';
    fout_img << this->max_rgb << '\n';

    for (int i = 0; i < this->height; i++)
    {
        for (int j = 0; j < this->width; j++)
        {
            Pixel &p = this->pixels[i * this->width + j];
            fout_img << p.r << ' ' << p.g << ' ' << p.b << ' ';
        }
        fout_img << '\n';
    }
    fout_img << std::endl;
}

void Image::WriteImageChanel(const std::string& path, int chanel) const
{
    std::ofstream fout_img(path+".ppm");
    if (!fout_img.is_open())
    {
        std::cerr << "Error opening image: " << path << '\n';
        std::exit(1);
    }

    fout_img << this->format << '\n';
    fout_img << this->width << ' ' << this->height << '\n';
    fout_img << this->max_rgb << '\n';

    for (int i = 0; i < this->height; i++)
    {
        for (int j = 0; j < this->width; j++)
        {
            Pixel &p = this->pixels[i * this->width + j];
            int *ch = (int*)&p;
            fout_img << ch[chanel] << ' ' << ch[chanel] << ' ' << ch[chanel] << ' ';
        }
        fout_img << '\n';
    }
    fout_img << std::endl;
}