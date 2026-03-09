#ifndef COMPILING
#include "./src/clcomplex.cl"
#endif

#define M_PI_3 (M_PI_F / 3.0f)
#define M_TAU (2 * M_PI)
#define M_PHI (1.618033988749894848)
#define M_I ((cdouble)(0, 1))

// p for parameter
#ifndef P_RADIUS
#define P_RADIUS 1
#endif

cdouble f(cdouble z, double t);

// remember that hue is in radians here
// speedup by using uint8s instead of floats?
double3 hsv2rgb(double3 hsv)
{
    // const double chroma = hsv[1] * hsv[2];
    // const double h_prime = hsv[0] / M_PI_3;
    // const double x = chroma * (1.0f - fabs(fmod(h_prime, 2) - 1.0f));
    
    // double3 rgb;
    // switch((int)h_prime)
    // {
    //     case 0:
    //         rgb = (double3)(chroma, x, 0);
    //         break;
    //     case 1:
    //         rgb = (double3)(x, chroma, 0);
    //         break;
    //     case 2:
    //         rgb = (double3)(0, chroma, x);
    //         break;
    //     case 3:
    //         rgb = (double3)(0, x, chroma);
    //         break;
    //     case 4:
    //         rgb = (double3)(x, 0, chroma);
    //         break;
    //     case 5:
    //         rgb = (double3)(chroma, 0, x);
    //         break;
    //     default:
    //         rgb = (double3)(0, 0, 0);    
    // }

    // const double m = hsv[2] - chroma;
    // return (rgb + (double3)(m, m, m)) * 255;

    double3 rgb = (double3)(0, 0, 0);
    for (int i = 0; i < 3; i++) {
        double k = fmod((5 - 2*i) + hsv[0]/M_PI_3, 6);
        rgb[i] = (hsv[2] - hsv[2]*hsv[1]*max(0.0, min(min(k, 4-k), 1.0)));
    }
    return rgb * 255;
}

double frac(double x)
{
    return x - floor(x);
}

double3 color(cdouble z)
{
    double hue = {
        carg(z)
    };

    double saturation = {
        // 0.5 + 0.5*frac(cabs(z))
        // sqrt(fabs(sinpi(2*cabs(z))))
        1
    };

    double value = {
        // 0.6 + 0.4*frac(cabs(z))
        1
    };

    return hsv2rgb((double3)(hue, saturation, value));
}

kernel void colorize(global uchar* images)
{
    const double radius = P_RADIUS;
    const double width = get_global_size(0);
    const double height = get_global_size(1);
    const double x = get_global_id(0);
    const double y = get_global_id(1);
    const double t = get_global_id(2) / (double)(get_global_size(2));
    const int idx = get_global_id(0) + get_global_id(1)*get_global_size(0) + get_global_id(2)*get_global_size(0)*get_global_size(1);
 
    const cdouble z = (cdouble)(
        (x - (width / 2)) / width * radius,
        -(y - (height / 2)) / height * radius
    );
    double3 rgbd = color(f(z, t));
    const uchar3 rgb = convert_uchar(rgbd);
    
    images[3*idx] = rgb[0];
    images[3*idx+1] = rgb[1];
    images[3*idx+2] = rgb[2];
}

