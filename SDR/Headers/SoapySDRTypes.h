#ifndef SoapySDRTypes_h
#define SoapySDRTypes_h

#include <stdbool.h>
#include <stddef.h>

// Opaque types
typedef struct SoapySDRDevice SoapySDRDevice;
typedef struct SoapySDRStream SoapySDRStream;
typedef struct SoapySDRKwargs SoapySDRKwargs;

// Constants
#define SOAPY_SDR_RX 0
#define SOAPY_SDR_TX 1
#define SOAPY_SDR_CF32 "CF32"
#define SOAPY_SDR_OVERFLOW 0x1

// Complex float type
typedef struct {
    float real;
    float imag;
} ComplexFloat;

// Device functions
SoapySDRDevice* SoapySDRDevice_make(const SoapySDRKwargs *args);
int SoapySDRDevice_unmake(SoapySDRDevice *device);
int SoapySDRDevice_setFrequency(SoapySDRDevice *device, const int direction, const size_t channel, const double frequency, const SoapySDRKwargs *args);
int SoapySDRDevice_setSampleRate(SoapySDRDevice *device, const int direction, const size_t channel, const double rate);
int SoapySDRDevice_setGain(SoapySDRDevice *device, const int direction, const size_t channel, const double gain);

// Stream functions
SoapySDRStream* SoapySDRDevice_setupStream(SoapySDRDevice *device, const int direction, const char *format, const size_t *channels, const size_t numChans, const SoapySDRKwargs *args);
int SoapySDRStream_activate(SoapySDRStream *stream);
int SoapySDRStream_deactivate(SoapySDRStream *stream);
int SoapySDRStream_read(SoapySDRStream *stream, void * const *buffs, const size_t numElems, int *flags, long long *timeNs, const long timeoutUs);
int SoapySDRStream_close(SoapySDRStream *stream);

#endif /* SoapySDRTypes_h */ 