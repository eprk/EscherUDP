function f = fft_freqs(sF,fftL)
    f = sF*(0:(floor(fftL/2)))/fftL;
end
