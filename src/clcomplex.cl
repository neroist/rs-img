//---------------------------------------------------------------------------//
// MIT License
//
// Copyright (c) 2017 StreamComputing
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//---------------------------------------------------------------------------//

#ifndef OPENCL_COMPLEX_MATH
#define OPENCL_COMPLEX_MATH

#define CONCAT(x, y) x##y

#define OPENCL_COMPLEX_MATH_FUNCS(complex_type, real_type, func_sufix, math_consts_sufix) \
    complex_type ccomplex(real_type r, real_type i) \
    { \
        return (complex_type)(r, i); \
    } \
    \
    real_type creal(complex_type z) \
    { \
        return z.x; \
    } \
    \
    real_type cre(complex_type z) \
    { \
        return z.x; \
    } \
    \
    real_type cimag(complex_type z) \
    { \
        return z.y; \
    } \
    \
    real_type cim(complex_type z) \
    { \
        return z.y; \
    } \
    \
    complex_type cadd(complex_type x, complex_type y) \
    { \
        return x + y; \
    } \
    \
    complex_type cadd_real(complex_type z, real_type r) \
    { \
        return (complex_type)(z.x + r, z.y); \
    } \
    \
    complex_type csub(complex_type x, complex_type y) \
    { \
        return x - y; \
    } \
    \
    complex_type csub_real(complex_type z, real_type r) \
    { \
        return (complex_type)(z.x - r, z.y); \
    } \
    \
    real_type cabs(complex_type z) \
    { \
        return length(z); \
    } \
    \
    real_type cmod(complex_type z) \
    { \
        return length(z); \
    } \
    \
    real_type cmodulus(complex_type z) \
    { \
        return length(z); \
    } \
    \
    real_type carg(complex_type z) \
    { \
        return atan2(z.y, z.x); \
    } \
    \
    real_type cphase(complex_type z) \
    { \
        return atan2(z.y, z.x); \
    } \
    \
    complex_type cmul(complex_type z1, complex_type z2) \
    { \
        real_type x1 = z1.x; \
        real_type y1 = z1.y; \
        real_type x2 = z2.x; \
        real_type y2 = z2.y; \
        return (complex_type)(x1 * x2 - y1 * y2, x1 * y2 + x2 * y1); \
    } \
    \
    complex_type cmul_real(complex_type z, real_type r) \
    { \
        return z * r; \
    } \
    \
    complex_type cmul_i(complex_type z) \
    { \
        return (complex_type)(-z.y, z.x); \
    } \
    \
    real_type cnorm(complex_type z) \
    { \
        /* Returns the squared magnitude of the complex number z. */ \
        /* The norm calculated by this function is also known as */ \
        /* field norm or absolute square. */ \
        real_type x = z.x; \
        real_type y = z.y; \
        return x * x + y * y; \
    } \
    \
    complex_type cdiv(complex_type z1, complex_type z2) \
    { \
        real_type x1 = z1.x; \
        real_type y1 = z1.y; \
        real_type x2 = z2.x; \
        real_type y2 = z2.y; \
        real_type iabs_z2 = CONCAT(1.0, func_sufix) / cnorm(z2); \
        return (complex_type)( \
            ((x1 * x2) + (y1 * y2)) * iabs_z2, \
            ((y1 * x2) - (x1 * y2)) * iabs_z2  \
        ); \
    } \
    \
    complex_type cdiv_real(complex_type z, real_type r) \
    { \
        return z / r; \
    } \
    \
    complex_type cconj(complex_type z) \
    { \
        return (complex_type)(z.x, -z.y); \
    } \
    \
    complex_type cproj(complex_type z) \
    { \
        if(isinf(z.x) || isinf(z.y)) \
        { \
            return (complex_type)(INFINITY, (copysign(CONCAT(0.0, func_sufix), z.y))); \
        } \
        return z; \
    } \
    \
    complex_type cpolar(real_type r, real_type theta) \
    { \
        /* Returns a complex number with magnitude r and phase angle theta. */ \
        return (complex_type)(r * cos(theta), r * sin(theta)); \
    } \
    \
    complex_type ccis(real_type theta) \
    { \
        /* Returns a complex number with magnitude r and phase angle theta. */ \
        return cpolar(CONCAT(0.0, func_sufix), theta); \
    } \
    \
    complex_type cexp(complex_type z) \
    { \
        /* The complex exponential function e^z for z = x+i*y */ \
        /* equals to e^x * cis(y), */ \
        /* or, e^x * (cos(y) + i*sin(y)) */ \
        real_type expx = exp(z.x); \
        return (complex_type)(expx * cos(z.y), expx * sin(z.y)); \
    } \
    \
    complex_type clog(complex_type z) \
    { \
        /* log(z) = log(abs(z)) + i * arg(z)  */ \
        return (complex_type)(log(length(z)),carg(z)); \
    } \
    \
    complex_type cln(complex_type z) \
    { \
        /* log(z) = log(abs(z)) + i * arg(z)  */ \
        return clog(z); \
    } \
    \
    complex_type clog10(complex_type z) \
    { \
        return clog(z) / log(CONCAT(10.0, func_sufix)); \
    } \
    \
    complex_type clog2(complex_type z) \
    { \
        return clog(z) / log(CONCAT(2.0, func_sufix)); \
    } \
    \
    complex_type clogbase(complex_type z, complex_type base) \
    { \
        return clog(z) / clog(base); \
    } \
    \
    complex_type cpow(complex_type z1, complex_type z2) \
    { \
        /* (z1)^(z2) = exp(z2 * log(z1)) = cexp(cmul(z2, clog(z1))) */ \
        return \
            cexp( \
                cmul( \
                    z2, \
                    clog(z1) \
                ) \
            ); \
    } \
    \
    complex_type cpow_real(complex_type z, real_type r) \
    { \
        return \
            cexp( \
                cmul_real( \
                    z, \
                    log(r) \
                ) \
            ); \
    } \
    \
    complex_type cinv(complex_type z) \
    { \
        return cdiv_real( \
            cconj(z), \
            cnorm(z) \
        ); \
    } \
    \
    complex_type csqrt(complex_type z) \
    { \
        /*  */ \
        real_type x = z.x; \
        real_type y = z.y; \
        if(x == CONCAT(0.0, func_sufix)) \
        { \
            real_type t = sqrt(fabs(y) / 2); \
            return (complex_type)(t, y < CONCAT(0.0, func_sufix) ? -t : t); \
        } \
        else \
        { \
            real_type t = sqrt(2 * cabs(z) + fabs(x)); \
            real_type u = t / 2; \
            return x > CONCAT(0.0, func_sufix) \
                ? (complex_type)(u, y / t) \
                : (complex_type)(fabs(y) / t, y < CONCAT(0.0, func_sufix) ? -u : u); \
        } \
    } \
    \
    complex_type ccbrt(complex_type z) \
    { \
        return cpow( \
            z, \
            CONCAT(0.33333333333333333, func_sufix) \
        ); \
    } \
    \
    complex_type csin(complex_type z) \
    { \
        const real_type x = z.x; \
        const real_type y = z.y; \
        return (complex_type)(sin(x) * cosh(y), cos(x) * sinh(y)); \
    } \
    \
    complex_type csinh(complex_type z) \
    { \
        const real_type x = z.x; \
        const real_type y = z.y; \
        return (complex_type)(sinh(x) * cos(y), cosh(x) * sin(y)); \
    } \
    \
    complex_type ccos(complex_type z) \
    { \
        const real_type x = z.x; \
        const real_type y = z.y; \
        return (complex_type)(cos(x) * cosh(y), -sin(x) * sinh(y)); \
    } \
    \
    complex_type ccosh(complex_type z) \
    { \
        const real_type x = z.x; \
        const real_type y = z.y; \
        return (complex_type)(cosh(x) * cos(y), sinh(x) * sin(y)); \
    } \
    \
    complex_type ctan(complex_type z) \
    { \
        return cdiv( \
            csin(z), \
            ccos(z) \
        ); \
    } \
    \
    complex_type ctanh(complex_type z) \
    { \
        return cdiv( \
            csinh(z), \
            ccosh(z) \
        ); \
    } \
    \
    complex_type casinh(complex_type z) \
    { \
        complex_type t = (complex_type)( \
            (z.x - z.y) * (z.x + z.y) + CONCAT(1.0, func_sufix), \
            CONCAT(2.0, func_sufix) * z.x * z.y \
        ); \
        t = csqrt(t) + z; \
        return clog(t); \
    } \
    \
    complex_type casin(complex_type z) \
    { \
        complex_type t = (complex_type)(-z.y, z.x); \
        t = casinh(t); \
        return (complex_type)(t.y, -t.x); \
    } \
    \
    complex_type cacosh(complex_type z) \
    { \
        return \
            CONCAT(2.0, func_sufix) * clog( \
                csqrt( \
                    CONCAT(0.5, func_sufix) * (z + CONCAT(1.0, func_sufix)) \
                ) \
                + csqrt( \
                    CONCAT(0.5, func_sufix) * (z - CONCAT(1.0, func_sufix)) \
                ) \
            ); \
    } \
    \
    complex_type cacos(complex_type z) \
    { \
        complex_type t = casin(z);\
        return (complex_type)( \
            CONCAT(M_PI_2, math_consts_sufix) - t.x, -t.y \
        ); \
    } \
    \
    complex_type catanh(complex_type z) \
    { \
        const real_type zy2 = z.y * z.y; \
        real_type n = CONCAT(1.0, func_sufix) + z.x; \
        real_type d = CONCAT(1.0, func_sufix) - z.x; \
        n = zy2 + n * n; \
        d = zy2 + d * d; \
        return (complex_type)( \
            CONCAT(0.25, func_sufix) * (log(n) - log(d)), \
            CONCAT(0.5, func_sufix) * atan2( \
                CONCAT(2.0, func_sufix) * z.y, \
                CONCAT(1.0, func_sufix) - zy2 - (z.x * z.x) \
            ) \
        ); \
    } \
    \
    complex_type catan(complex_type z) \
    { \
        const real_type zx2 = z.x * z.x; \
        real_type n = z.y + CONCAT(1.0, func_sufix); \
        real_type d = z.y - CONCAT(1.0, func_sufix); \
        n = zx2 + n * n; \
        d = zx2 + d * d; \
        return (complex_type)( \
            CONCAT(0.5, func_sufix) * atan2( \
                CONCAT(2.0, func_sufix) * z.x, \
                CONCAT(1.0, func_sufix) - zx2 - (z.y * z.y) \
            ), \
            CONCAT(0.25, func_sufix) * (log(n / d)) \
        ); \
    }


// double complex
#if defined(cl_khr_fp64) && !defined(CLCOMPLEX_USE_FLOAT)
#   pragma OPENCL EXTENSION cl_khr_fp64 : enable
    typedef double real;
    typedef double2 real2;
    typedef double3 real3;
    typedef double2 cmplx;
    OPENCL_COMPLEX_MATH_FUNCS(double2, double, , )
#else
    typedef float real;
    typedef float2 real2;
    typedef float3 real3;
    typedef float2 cmplx;
    OPENCL_COMPLEX_MATH_FUNCS(float2, float, f, _F)
#endif

#undef FNAME
#undef CONCAT
#endif // OPENCL_COMPLEX_MATH