#ifndef SDR_SHIM_H
#define SDR_SHIM_H

#include <SoapySDR/Device.h>
#include <SoapySDR/Formats.h>
#include <SoapySDR/Version.h>
#include <SoapySDR/Config.h>
#include <SoapySDR/Constants.h>
#include <SoapySDR/Errors.h>
#include <SoapySDR/Logger.h>
#include <SoapySDR/Modules.h>
#include <SoapySDR/Time.h>
#include <SoapySDR/Types.h>

typedef struct {
    float real;
    float imag;
} ComplexFloat;

#endif /* SDR_SHIM_H */ 
