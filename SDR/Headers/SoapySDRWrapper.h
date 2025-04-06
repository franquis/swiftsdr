#ifndef SoapySDRWrapper_h
#define SoapySDRWrapper_h

#include <stdbool.h>
#include <SoapySDR/Device.h>
#include <SoapySDR/Formats.h>
#include <SoapySDR/Version.h>
#include <SoapySDR/Types.h>
#include <SoapySDR/Constants.h>

// Direction constants
#define SOAPY_SDR_TX 0
#define SOAPY_SDR_RX 1

// Format constants
#define SOAPY_SDR_CF32 "CF32"
#define SOAPY_SDR_CS16 "CS16"
#define SOAPY_SDR_CU16 "CU16"
#define SOAPY_SDR_CS8  "CS8"
#define SOAPY_SDR_CU8  "CU8"
#define SOAPY_SDR_CS12 "CS12"
#define SOAPY_SDR_CU12 "CU12"

// Status flags
#define SOAPY_SDR_HAS_TIME    0x1
#define SOAPY_SDR_END_BURST   0x2
#define SOAPY_SDR_HAS_FREQ    0x4
#define SOAPY_SDR_END_ABRUPT  0x8
#define SOAPY_SDR_ONE_PACKET  0x10
#define SOAPY_SDR_MORE_FRAGMENTS  0x20
#define SOAPY_SDR_WAIT_TRIGGER    0x40
#define SOAPY_SDR_TIMEOUT     0x80
#define SOAPY_SDR_OVERFLOW    0x100
#define SOAPY_SDR_UNDERFLOW   0x200
#define SOAPY_SDR_LATE_BURST  0x400

#endif /* SoapySDRWrapper_h */ 