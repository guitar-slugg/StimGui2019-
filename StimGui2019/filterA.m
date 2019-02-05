%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  A-weighting Filter                  %
%              with Matlab Implementation              %
%                                                      %
% Author: M.Sc. Eng. Hristo Zhivomirov        06/01/14 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function xA = filterA(x, fs, varargin)

% function: xA = filterA(x, fs, plotFilter)
% x - singnal in the time domain
% fs - sampling frequency, Hz
% type 'plot' in the place of varargin if one want to make a plot of freq response
% xA - filtered signal in the time domain

% filter coefficients
c1 = 3.5041384e16;
c2 = 20.598997^2;
c3 = 107.65265^2;
c4 = 737.86223^2;
c5 = 12194.217^2;

% represent x as row-vector if it is not
if size(x,1) > 1
    x = x';
end

% calculate xlen
xlen = length(x);

% calculate the number of unique points
NumUniquePts = ceil((xlen+1)/2);

% take fft of x
X = fft(x);

% fft is symmetric, throw away second half
X = X(1:NumUniquePts);

% frequency vector with NumUniquePts points
f = (0:NumUniquePts-1)*fs/xlen;

% evaluate A-weighting filter
f = f.^2;
num = c1*f.^4;
den = ((c2+f).^2) .* (c3+f) .* (c4+f) .* ((c5+f).^2);
A = num./den;

% filtering
XA = X.*A;

% perform ifft
if rem(xlen, 2)                     % odd xlen excludes Nyquist point
    % reconstruct the whole spectrum
    XA = [XA conj(XA(end:-1:2))];
    
    % take ifft of XA
    xA = real(ifft(XA));
else                                % even xlen includes Nyquist point
    % reconstruct the whole spectrum
    XA = [XA conj(XA(end-1:-1:2))];
    
    % take ifft of XA
    xA = real(ifft(XA));
end

% plot A-weighting filter (if enabled)
if strcmp(varargin, 'plot')
    
    figure
    semilogx(sqrt(f), 10*log10(A), 'r')
    grid on
    set(gca, 'FontName', 'Times New Roman', 'FontSize', 14)
    title('A-weighting filter freq response')
    xlabel('Frequency, Hz')
    ylabel('Magnitude, dB')
    
end

end