import 'dart:math' as math;

class DftProcessor {
  const DftProcessor();

  PsdResult computePsd({
    required List<double> signal,
    required double samplingRate,
    bool applyHannWindow = true,
  }) {
    if (signal.isEmpty || samplingRate <= 0) {
      return const PsdResult(frequencies: [], powers: [], deltaF: 0.0);
    }

    final int originalN = signal.length;
    int n = 1;
    while (n < originalN) {
      n <<= 1;
    }
    if (n < 8) n = 8;

    final real = List<double>.filled(n, 0.0);
    final imag = List<double>.filled(n, 0.0);

    double windowPowerSum = 0.0;
    if (applyHannWindow && originalN > 1) {
      for (int i = 0; i < originalN; i++) {
        final w = 0.5 * (1.0 - math.cos(2.0 * math.pi * i / (originalN - 1)));
        real[i] = signal[i] * w;
        windowPowerSum += w * w;
      }
    } else {
      for (int i = 0; i < originalN; i++) {
        real[i] = signal[i];
      }
      windowPowerSum = originalN.toDouble();
    }

    if (windowPowerSum <= 0.0) {
      windowPowerSum = 1.0;
    }

    _cooleyTukeyFft(real, imag, n);

    final int halfN = n ~/ 2;
    final deltaF = samplingRate / n;
    final frequencies = List<double>.generate(halfN, (i) => i * deltaF);
    final powers = List<double>.filled(halfN, 0.0);

    powers[0] = (real[0] * real[0] + imag[0] * imag[0]) / (samplingRate * windowPowerSum);

    final scale = 2.0 / (samplingRate * windowPowerSum);
    for (int k = 1; k < halfN; k++) {
      powers[k] = (real[k] * real[k] + imag[k] * imag[k]) * scale;
    }

    return PsdResult(frequencies: frequencies, powers: powers, deltaF: deltaF);
  }

  void _cooleyTukeyFft(List<double> real, List<double> imag, int n) {
    int j = 0;
    for (int i = 0; i < n - 1; i++) {
      if (i < j) {
        final tempR = real[i];
        real[i] = real[j];
        real[j] = tempR;

        final tempI = imag[i];
        imag[i] = imag[j];
        imag[j] = tempI;
      }
      int k = n >> 1;
      while (k <= j) {
        j -= k;
        k >>= 1;
      }
      j += k;
    }

    for (int len = 2; len <= n; len <<= 1) {
      final double angle = -2.0 * math.pi / len;
      final double wlenR = math.cos(angle);
      final double wlenI = math.sin(angle);

      for (int i = 0; i < n; i += len) {
        double wR = 1.0;
        double wI = 0.0;
        final int halfLen = len >> 1;

        for (int k = 0; k < halfLen; k++) {
          final int uIndex = i + k;
          final int vIndex = i + k + halfLen;

          final double uR = real[uIndex];
          final double uI = imag[uIndex];

          final double vR = real[vIndex] * wR - imag[vIndex] * wI;
          final double vI = real[vIndex] * wI + imag[vIndex] * wR;

          real[uIndex] = uR + vR;
          imag[uIndex] = uI + vI;

          real[vIndex] = uR - vR;
          imag[vIndex] = uI - vI;

          final double nextWR = wR * wlenR - wI * wlenI;
          final double nextWI = wR * wlenI + wI * wlenR;
          wR = nextWR;
          wI = nextWI;
        }
      }
    }
  }
}

class PsdResult {
  final List<double> frequencies;
  final List<double> powers;
  final double deltaF;

  const PsdResult({
    required this.frequencies,
    required this.powers,
    required this.deltaF,
  });

  double integrateBandPower(double minFreq, double maxFreq) {
    if (frequencies.isEmpty || minFreq >= maxFreq) return 0.0;
    double sum = 0.0;
    for (int i = 0; i < frequencies.length; i++) {
      final f = frequencies[i];
      if (f >= minFreq && f < maxFreq) {
        sum += powers[i] * deltaF;
      }
    }
    return sum;
  }
}
