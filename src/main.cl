#ifndef COMPILING
#include "./src/clcomplex.cl"
#endif

#define M_PI_3 ((real)((real)(M_PI) / (real)(3.0)))
#define M_TAU ((real)(2 * M_PI))
#define M_PHI ((real)(1.618033988749894848))
#define M_I ((cmplx)(0, 1))

// p for parameter
#ifndef P_RADIUS
#define P_RADIUS 1
#endif

cmplx f(cmplx z, real t);

// remember that hue is in radians here
real3 hsv2rgb(real3 hsv)
{
    real3 rgb = (real3)(0, 0, 0);
    for (int i = 0; i < 3; i++) {
        real k = fmod((5 - 2*i) + hsv[0]/M_PI_3, 6);
        rgb[i] = (hsv[2] - hsv[2]*hsv[1]*max(0.0, min(min(k, 4-k), 1.0)));
    }
    return rgb * 255;
}

real frac(real x)
{
    return x - floor(x);
}

real3 color(cmplx z)
{
    real hue = {
        carg(z)
    };

    real saturation = {
        // 0.5 + 0.5*frac(cabs(z))
        // sqrt(fabs(sinpi(2*cabs(z))))
        1
    };

    real value = {
        // 0.6 + 0.4*frac(cabs(z))
        1
    };

    return hsv2rgb((real3)(hue, saturation, value));
}

kernel void colorize(global uchar* images)
{
    const real radius = P_RADIUS;
    const real width = get_global_size(0);
    const real height = get_global_size(1);
    const real x = get_global_id(0);
    const real y = get_global_id(1);
    const real t = (get_global_id(2) - 1) / (real)(get_global_size(2));
    const int idx = get_global_id(0) + get_global_id(1)*get_global_size(0) + get_global_id(2)*get_global_size(0)*get_global_size(1);
 
    const cmplx z = (cmplx)(
        (x - (width / 2)) / width * radius,
        -(y - (height / 2)) / height * radius
    );
    const real3 rgbd = color(f(z, t));
    
    images[3*idx] = (uchar)(rgbd[0]);
    images[3*idx+1] = (uchar)(rgbd[1]);
    images[3*idx+2] = (uchar)(rgbd[2]);
}

