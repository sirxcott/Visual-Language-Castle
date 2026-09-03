// Offline generator for the castle entrance audio cue.
//
// Run from the app root: `dart run tool/generate_entrance_audio.dart`
// It synthesises `assets/audio/castle_gate.wav` (16-bit mono, 44.1 kHz) so the
// project ships an original, dependency-free sound instead of a binary blob of
// unknown provenance. Timings below are baked to match the entrance animation:
//
//   0.00s  mechanism engages, chains take up slack
//   0.42s  hinges load and the doors break free (creak begins)
//   2.55s  doors reach full open, settling thud and chain slack
//   4.40s  tail fades out

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;
const double totalSeconds = 4.4;
const double doorBreakFree = 0.42;
const double doorFullyOpen = 2.55;

void main() {
  final sampleCount = (sampleRate * totalSeconds).round();
  final dry = Float64List(sampleCount);
  final wetSource = Float64List(sampleCount);
  final random = Random(43043);

  _addRumble(dry);
  _addHingeGroan(dry);
  _addMechanism(wetSource, random);
  _addChains(wetSource, random);
  _addCreak(wetSource, random, start: doorBreakFree, end: doorFullyOpen, fromHz: 240, toHz: 610, gain: 1.0);
  _addCreak(wetSource, random, start: 0.92, end: doorFullyOpen + 0.07, fromHz: 310, toHz: 505, gain: 0.7);
  _addSettle(dry, wetSource, random);

  final wet = _reverb(wetSource);
  final mix = Float64List(sampleCount);
  for (var i = 0; i < sampleCount; i++) {
    mix[i] = dry[i] + wetSource[i] + 0.3 * wet[i];
  }

  _softClip(mix);
  _normalize(mix, 0.72);
  _applyEdgeFades(mix);

  final file = File('assets/audio/castle_gate.wav');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(_encodeWav(mix));
  stdout.writeln('Wrote ${file.path} (${(file.lengthSync() / 1024).round()} KB, ${totalSeconds}s)');
}

/// Deep mechanical rumble of the unseen mechanism behind the walls.
void _addRumble(Float64List out) {
  final noise = Random(7);
  var lowpassed = 0.0;
  const lowpassCoefficient = 0.0035;
  for (var i = 0; i < out.length; i++) {
    final t = i / sampleRate;
    lowpassed += ((noise.nextDouble() * 2 - 1) - lowpassed) * lowpassCoefficient;

    final drift = 1 + 0.02 * sin(2 * pi * 0.37 * t);
    final body =
        0.55 * sin(2 * pi * 33 * drift * t) +
        0.32 * sin(2 * pi * 49.5 * drift * t + 0.8) +
        0.16 * sin(2 * pi * 77 * t + 2.1);

    final envelope = _segmentEnvelope(t, attackTo: 0.5, holdUntil: 3.4, releaseUntil: totalSeconds);
    // Slow effort swell while the doors are actually moving.
    final effort = 0.75 + 0.25 * _bump(t, doorBreakFree, doorFullyOpen);
    out[i] += (body * 0.26 + lowpassed * 9.0 * 0.22) * envelope * effort;
  }
}

/// Low sawtooth groan of heavy iron hinges taking the weight.
void _addHingeGroan(Float64List out) {
  var phase = 0.0;
  var lowpassed = 0.0;
  for (var i = 0; i < out.length; i++) {
    final t = i / sampleRate;
    if (t < 0.5 || t > doorFullyOpen + 0.1) continue;

    final progress = ((t - 0.5) / (doorFullyOpen - 0.4)).clamp(0.0, 1.0);
    final frequency = 86 + 34 * progress + 4.5 * sin(2 * pi * 5.3 * t);
    phase += frequency / sampleRate;
    phase -= phase.floorToDouble();

    final saw = 2 * phase - 1;
    lowpassed += (saw - lowpassed) * 0.05;

    final envelope = _segmentEnvelope(t - 0.5, attackTo: 0.45, holdUntil: 1.5, releaseUntil: doorFullyOpen - 0.4);
    out[i] += lowpassed * 0.11 * envelope;
  }
}

/// Ratcheting drive that starts before the doors move and drops away at the end.
void _addMechanism(Float64List out, Random random) {
  final filter = _Biquad();
  var t = 0.05;
  while (t < doorFullyOpen + 0.05) {
    final progress = (t / doorFullyOpen).clamp(0.0, 1.0);
    final amplitude = 0.10 * (0.55 + 0.45 * sin(pi * progress)) * (0.85 + 0.3 * random.nextDouble());
    _addBurst(
      out,
      filter,
      startSeconds: t,
      durationSeconds: 0.03,
      centerHz: 1250 + random.nextDouble() * 420,
      q: 5,
      amplitude: amplitude,
      random: random,
    );
    // Ratchet accelerates as the mechanism gets going, then eases off.
    final rate = 8.5 + 6.5 * sin(pi * progress);
    t += 1 / rate;
  }
}

/// Distant chains rattling somewhere behind the stonework.
void _addChains(Float64List out, Random random) {
  final filter = _Biquad();
  var t = 0.08;
  while (t < 3.15) {
    final density = t < 0.85 ? 26.0 : (t < doorFullyOpen ? 15.0 : 9.0);
    final amplitude = 0.075 * (0.4 + 0.6 * random.nextDouble()) * (t < 0.85 ? 1.0 : 0.8);
    _addBurst(
      out,
      filter,
      startSeconds: t,
      durationSeconds: 0.05 + random.nextDouble() * 0.11,
      centerHz: 1150 + random.nextDouble() * 2250,
      q: 24,
      amplitude: amplitude,
      random: random,
    );
    t += (0.35 + random.nextDouble()) / density;
  }
}

/// Stick-slip creak of ancient timber turning on its hinge.
void _addCreak(
  Float64List out,
  Random random, {
  required double start,
  required double end,
  required double fromHz,
  required double toHz,
  required double gain,
}) {
  final filter = _Biquad();
  final noise = Random(random.nextInt(1 << 30));
  final startIndex = (start * sampleRate).round();
  final endIndex = min(out.length, (end * sampleRate).round());

  for (var i = startIndex; i < endIndex; i++) {
    final t = i / sampleRate;
    final progress = (i - startIndex) / (endIndex - startIndex);

    final wobble = 1 + 0.13 * sin(2 * pi * 3.1 * t) + 0.06 * sin(2 * pi * 7.9 * t + 1.1);
    filter.setBandpass((fromHz + (toHz - fromHz) * progress) * wobble, 13);
    final voice = filter.process(noise.nextDouble() * 2 - 1);

    // Irregular grain: the door grips, releases, grips again.
    final grainRate = 13 + 11 * progress;
    final grain = pow(0.5 + 0.5 * sin(2 * pi * grainRate * t + 2.2 * sin(2 * pi * 1.7 * t)), 3).toDouble();

    // Heavy at the break-free moment, easing as momentum builds.
    final envelope = sin(pi * progress.clamp(0.0, 1.0)) * (0.55 + 0.45 * (1 - progress));
    out[i] += voice * grain * envelope * 0.9 * gain;
  }
}

/// The doors reaching their stops: a low thud plus slack chain settling.
void _addSettle(Float64List dry, Float64List wetSource, Random random) {
  final startIndex = (doorFullyOpen * sampleRate).round();
  for (var i = startIndex; i < dry.length; i++) {
    final t = (i - startIndex) / sampleRate;
    final decay = exp(-4.2 * t);
    dry[i] += (0.30 * sin(2 * pi * 52 * t) + 0.12 * sin(2 * pi * 79 * t)) * decay;
  }

  final filter = _Biquad();
  for (var index = 0; index < 5; index++) {
    _addBurst(
      wetSource,
      filter,
      startSeconds: doorFullyOpen + 0.06 + index * 0.17 + random.nextDouble() * 0.08,
      durationSeconds: 0.09 + random.nextDouble() * 0.13,
      centerHz: 900 + random.nextDouble() * 1700,
      q: 26,
      amplitude: 0.05 * (1 - index / 6),
      random: random,
    );
  }
}

/// Exponentially decaying band-passed noise burst — the metallic hit primitive.
void _addBurst(
  Float64List out,
  _Biquad filter,
  {required double startSeconds,
  required double durationSeconds,
  required double centerHz,
  required double q,
  required double amplitude,
  required Random random}) {
  final startIndex = (startSeconds * sampleRate).round();
  if (startIndex >= out.length) return;
  final endIndex = min(out.length, startIndex + (durationSeconds * sampleRate).round());

  filter.reset();
  filter.setBandpass(centerHz, q);
  final decay = 5.0 / max(durationSeconds, 0.001);

  for (var i = startIndex; i < endIndex; i++) {
    final t = (i - startIndex) / sampleRate;
    final excite = t < 0.0015 ? random.nextDouble() * 2 - 1 : (random.nextDouble() * 2 - 1) * 0.12;
    out[i] += filter.process(excite) * exp(-decay * t) * amplitude * 6;
  }
}

/// Small Schroeder reverb so the mechanism reads as "behind the walls".
Float64List _reverb(Float64List input) {
  final combs = [
    _Comb(1687, 0.78),
    _Comb(1601, 0.77),
    _Comb(2053, 0.755),
    _Comb(2251, 0.744),
  ];
  final allpasses = [_AllPass(347, 0.7), _AllPass(113, 0.7)];

  final out = Float64List(input.length);
  for (var i = 0; i < input.length; i++) {
    var value = 0.0;
    for (final comb in combs) {
      value += comb.process(input[i]);
    }
    value *= 0.25;
    for (final allpass in allpasses) {
      value = allpass.process(value);
    }
    out[i] = value;
  }
  return out;
}

double _segmentEnvelope(double t, {required double attackTo, required double holdUntil, required double releaseUntil}) {
  if (t <= 0) return 0;
  if (t < attackTo) return t / attackTo;
  if (t < holdUntil) return 1;
  if (t < releaseUntil) return 1 - (t - holdUntil) / (releaseUntil - holdUntil);
  return 0;
}

double _bump(double t, double start, double end) {
  if (t < start || t > end) return 0;
  return sin(pi * (t - start) / (end - start));
}

void _softClip(Float64List buffer) {
  for (var i = 0; i < buffer.length; i++) {
    buffer[i] = tanhApprox(buffer[i]);
  }
}

double tanhApprox(double x) {
  final e = exp(-2 * x.clamp(-8.0, 8.0));
  return (1 - e) / (1 + e);
}

void _normalize(Float64List buffer, double peak) {
  var maximum = 0.0;
  for (final value in buffer) {
    maximum = max(maximum, value.abs());
  }
  if (maximum == 0) return;
  final scale = peak / maximum;
  for (var i = 0; i < buffer.length; i++) {
    buffer[i] *= scale;
  }
}

void _applyEdgeFades(Float64List buffer) {
  final fadeIn = (0.02 * sampleRate).round();
  final fadeOut = (0.5 * sampleRate).round();
  for (var i = 0; i < fadeIn; i++) {
    buffer[i] *= i / fadeIn;
  }
  for (var i = 0; i < fadeOut; i++) {
    buffer[buffer.length - 1 - i] *= i / fadeOut;
  }
}

Uint8List _encodeWav(Float64List samples) {
  final dataBytes = samples.length * 2;
  final bytes = BytesBuilder();
  final header = ByteData(44);

  void writeAscii(int offset, String value) {
    for (var i = 0; i < value.length; i++) {
      header.setUint8(offset + i, value.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  header.setUint32(4, 36 + dataBytes, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little); // PCM
  header.setUint16(22, 1, Endian.little); // mono
  header.setUint32(24, sampleRate, Endian.little);
  header.setUint32(28, sampleRate * 2, Endian.little); // byte rate
  header.setUint16(32, 2, Endian.little); // block align
  header.setUint16(34, 16, Endian.little); // bits per sample
  writeAscii(36, 'data');
  header.setUint32(40, dataBytes, Endian.little);
  bytes.add(header.buffer.asUint8List());

  final pcm = ByteData(dataBytes);
  for (var i = 0; i < samples.length; i++) {
    final clamped = samples[i].clamp(-1.0, 1.0);
    pcm.setInt16(i * 2, (clamped * 32767).round(), Endian.little);
  }
  bytes.add(pcm.buffer.asUint8List());

  return bytes.toBytes();
}

class _Biquad {
  double _b0 = 1, _b1 = 0, _b2 = 0, _a1 = 0, _a2 = 0;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  void setBandpass(double frequency, double q) {
    final w0 = 2 * pi * frequency.clamp(20.0, sampleRate / 2 - 100) / sampleRate;
    final alpha = sin(w0) / (2 * q);
    final a0 = 1 + alpha;
    _b0 = alpha / a0;
    _b1 = 0;
    _b2 = -alpha / a0;
    _a1 = -2 * cos(w0) / a0;
    _a2 = (1 - alpha) / a0;
  }

  void reset() {
    _x1 = _x2 = _y1 = _y2 = 0;
  }

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}

class _Comb {
  _Comb(int length, this.feedback) : _buffer = Float64List(length);

  final Float64List _buffer;
  final double feedback;
  int _index = 0;

  double process(double input) {
    final output = _buffer[_index];
    _buffer[_index] = input + output * feedback;
    _index = (_index + 1) % _buffer.length;
    return output;
  }
}

class _AllPass {
  _AllPass(int length, this.gain) : _buffer = Float64List(length);

  final Float64List _buffer;
  final double gain;
  int _index = 0;

  double process(double input) {
    final buffered = _buffer[_index];
    final output = -input + buffered;
    _buffer[_index] = input + buffered * gain;
    _index = (_index + 1) % _buffer.length;
    return output;
  }
}
