import 'dart:html';
import 'dart:math';

class Colour {
    static const double defaultGamma = 2.2;
    static const List<double> referenceWhite = <double>[095.047, 100.000, 108.883];
    static const double xyzEpsilon = 0.008856;
    static const double xyzKappa = 903.3;

    int _alpha;

    int _red;
    int _green;
    int _blue;

    bool _hsv_dirty = true;
    double _hue = 0.0;
    double _saturation = 0.0;
    double _value = 0.0;

    bool _lab_dirty = true;
    double _lab_lightness = 0.0;
    double _lab_a = 0.0;
    double _lab_b = 0.0;

    // Constructors ###################################################################################

    Colour([int red = 0, int green = 0, int blue = 0, int alpha = 0xFF]) {
        this.red = red.clamp(0, 0xFF);
        this.green = green.clamp(0, 0xFF);
        this.blue = blue.clamp(0, 0xFF);
        this.alpha = alpha.clamp(0,0xFF);
    }

    factory Colour.from(Colour other) {
        final Colour col = new Colour(other.red, other.green, other.blue, other.alpha);

        if (!other._hsv_dirty) {
            col.setHSV(other._hue, other._saturation, other._value);
            col._hsv_dirty = false;
        }

        if (!other._lab_dirty) {
            col.setLAB(other._lab_lightness, other._lab_a, other._lab_b);
            col._lab_dirty = false;
        }

        return col;
    }

    factory Colour.double(double red, double green, double blue, [double alpha = 1.0]) {
        return new Colour()
            ..redDouble = red
            ..greenDouble = green
            ..blueDouble = blue
            ..alphaDouble = alpha;
    }

    factory Colour.fromHex(int hex, [bool useAlpha = false]) {
        if (useAlpha) {
            final int red = (hex & 0xFF000000) >> 24;
            final int green = (hex & 0x00FF0000) >> 16;
            final int blue = (hex & 0x0000FF00) >> 8;
            final int alpha = (hex & 0x000000FF);

            return new Colour(red, green, blue, alpha);
        } else {
            final int red = (hex & 0xFF0000) >> 16;
            final int green = (hex & 0x00FF00) >> 8;
            final int blue = (hex & 0x0000FF);

            return new Colour(red, green, blue);
        }
    }

    factory Colour.fromHexString(String hex) {
        return new Colour.fromHex(int.tryParse(hex, radix:16) ?? 0, hex.length >= 8);
    }

    factory Colour.fromStyleString(String hex) {
        return new Colour.fromHexString(hex.substring(1));
    }

    factory Colour.hsv(double h, double s, double v) {
        return new Colour()..setHSV(h, s, v);
    }

    factory Colour.lab(double l, double a, double b) {
        return new Colour()..setLAB(l, a, b);
    }

    factory Colour.labScaled(double l, double a, double b) {
        return new Colour()..setLABScaled(l, a, b);
    }

    // Getters/setters ###################################################################################

    // RGB

    int get red   => _red;
    int get green => _green;
    int get blue  => _blue;
    int get alpha => _alpha;

    set red(int val)   { _red   = val.clamp(0,0xFF); this._dirty(); }
    set green(int val) { _green = val.clamp(0,0xFF); this._dirty(); }
    set blue(int val)  { _blue  = val.clamp(0,0xFF); this._dirty(); }
    set alpha(int val) { _alpha = val.clamp(0,0xFF); }

    double get redDouble =>     red /   0xFF;
    double get greenDouble =>   green / 0xFF;
    double get blueDouble =>    blue /  0xFF;
    double get alphaDouble =>   alpha / 0xFF;

    set redDouble(double val)  { this.red   = (val*0xFF).floor(); }
    set greenDouble(double val){ this.green = (val*0xFF).floor(); }
    set blueDouble(double val) { this.blue  = (val*0xFF).floor(); }
    set alphaDouble(double val){ this.alpha = (val*0xFF).floor(); }

    void setRGB(int red, int green, int blue) {
        this.red = red;
        this.green = green;
        this.blue = blue;
    }

    // HSV

    double get hue        { this._checkHSV(); return _hue; }
    double get saturation { this._checkHSV(); return _saturation; }
    double get value      { this._checkHSV(); return _value; }

    set hue(double val)        { this._checkHSV(); _hue        = val; this._updateRGBfromHSV(); }
    set saturation(double val) { this._checkHSV(); _saturation = val; this._updateRGBfromHSV(); }
    set value(double val)      { this._checkHSV(); _value      = val; this._updateRGBfromHSV(); }

    void setHSV(double h, double s, double v) {
        this._hue = h;
        this._saturation = s;
        this._value = v;
        this._updateRGBfromHSV();
    }

    // LAB

    double get lab_lightness { this._checkLAB(); return _lab_lightness; }
    double get lab_a         { this._checkLAB(); return _lab_a; }
    double get lab_b         { this._checkLAB(); return _lab_b; }

    set lab_lightness(double val) { this._checkLAB(); _lab_lightness = val; this._updateRGBfromLAB(); }
    set lab_a(double val)         { this._checkLAB(); _lab_a         = val; this._updateRGBfromLAB(); }
    set lab_b(double val)         { this._checkLAB(); _lab_b         = val; this._updateRGBfromLAB(); }

    void setLAB(double l, double a, double b) {
        this._lab_lightness = l;
        this._lab_a = a;
        this._lab_b = b;
        this._updateRGBfromLAB();
    }

    double _lab_scale_l(double val, bool reverse) {
        return reverse ? val*100 : val*0.01;
    }

    static const double _labMinA = -86.18463649762525;
    static const double _labMaxA = 98.25421868616114;
    double _lab_scale_a(double val, bool reverse) {
        if (reverse) {
            if (val < 0.5) {
                return (1 - (val * 2)) * _labMinA;
            } else {
                return ((val - 0.5) * 2) * _labMaxA;
            }
        } else {
            if (val < 0) {
                return (1 - (val / _labMinA)) * 0.5;
            } else {
                return (val / _labMaxA) * 0.5 + 0.5;
            }
        }
    }

    static const double _labMinB = -107.86368104495168;
    static const double _labMaxB = 94.48248544644461;
    double _lab_scale_b(double val, bool reverse) {
        if (reverse) {
            if (val < 0.5) {
                return (1 - (val * 2)) * _labMinB;
            } else {
                return ((val - 0.5) * 2) * _labMaxB;
            }
        } else {
            if (val < 0) {
                return (1 - (val / _labMinB)) * 0.5;
            } else {
                return (val / _labMaxB) * 0.5 + 0.5;
            }
        }
    }

    double get lab_lightness_scaled => _lab_scale_l(this.lab_lightness, false);
    double get lab_a_scaled         => _lab_scale_a(this.lab_a, false);
    double get lab_b_scaled         => _lab_scale_b(this.lab_b, false);

    set lab_lightness_scaled(double val) { this.lab_lightness = _lab_scale_l(val, true); }
    set lab_a_scaled(double val)         { this.lab_a = _lab_scale_a(val, true); }
    set lab_b_scaled(double val)         { this.lab_b = _lab_scale_b(val, true); }

    void setLABScaled(double l, double a, double b) {
        this._lab_lightness = _lab_scale_l(l, true);
        this._lab_a = _lab_scale_a(a, true);
        this._lab_b = _lab_scale_b(b, true);
        this._updateRGBfromLAB();
    }

    // Methods ###################################################################################

    void setFrom(Colour colour) {
        this._red = colour._red;
        this._green = colour._green;
        this._blue = colour._blue;
        this._dirty();
    }

    @override
    String toString() {
        return "rgb($red, $green, $blue, $alpha)";
    }

    int toHex([bool useAlpha = false]) {
        if (useAlpha) {
            return (red << 24) | (green << 16) | (blue << 8) | alpha;
        }
        return (red << 16) | (green << 8) | blue;
    }

    String toHexString([bool useAlpha = false]) {
        return this.toHex(useAlpha).toRadixString(16).padLeft(useAlpha ? 8 : 6, "0").toUpperCase();
    }

    String toStyleString([bool useAlpha = false, bool rgba = false]) {
        if (rgba) {
            if (useAlpha) {
                return "rgba($red,$green,$blue,$alphaDouble)";
            }
            return "rgb($red,$green,$blue)";
        }
        return "#${this.toHexString(useAlpha)}";
    }

    bool matchFromImageData(ImageData data, int offset) {
        return data.data[offset] == this.red && data.data[offset+1] == this.green && data.data[offset+2] == this.blue && data.data[offset+3] == this.alpha;
    }

    Colour mixRGB(Colour other, double fraction) {
        fraction = fraction.clamp(0.0, 1.0);
        return (this * (1-fraction)) + (other * fraction);
    }

    Colour mixGamma(Colour other, double fraction, [double gamma = defaultGamma]) {
        fraction = fraction.clamp(0.0, 1.0);
        final double inverse = 1.0 / gamma;

        final double r = pow( _lerp( pow(this.redDouble, gamma), pow(other.redDouble, gamma), fraction), inverse);
        final double g = pow( _lerp( pow(this.greenDouble, gamma), pow(other.greenDouble, gamma), fraction), inverse);
        final double b = pow( _lerp( pow(this.blueDouble, gamma), pow(other.blueDouble, gamma), fraction), inverse);
        final double a = _lerp(this.alphaDouble, other.alphaDouble, fraction);

        return new Colour.double(r,g,b,a);
    }

    Colour mix(Colour other, double fraction, [bool useGamma = false, double gamma = defaultGamma]) {
        if (useGamma) {
            return this.mixGamma(other, fraction, gamma);
        }
        return this.mixRGB(other, fraction);
    }

    static double _lerp(double first, double second, double fraction) {
        return (first * (1-fraction) + second * fraction);
    }

    void _dirty() {
        this._hsv_dirty = true;
        this._lab_dirty = true;
    }

    // HSV ###################################################################################

    void _checkHSV() {
        if (this._hsv_dirty) {
            this._updateHSVfromRGB();
        }
    }

    void _updateHSVfromRGB() {
        this._hsv_dirty = false;

        List<double> hsv = RGBtoHSV(this.redDouble, this.greenDouble, this.blueDouble);

        this._hue = hsv[0];
        this._saturation = hsv[1];
        this._value = hsv[2];

        hsv = null;
    }

    void _updateRGBfromHSV() {
        this._hsv_dirty = false;

        List<double> rgb = HSVtoRGB(this._hue, this._saturation, this._value);

        this.redDouble = rgb[0];
        this.greenDouble = rgb[1];
        this.blueDouble = rgb[2];

        rgb = null;
    }

    // LAB ###################################################################################

    void _checkLAB() {
        if (this._lab_dirty) {
            this._updateLABfromRGB();
        }
    }

    void _updateLABfromRGB() {
        this._lab_dirty = false;

        List<double> lab = RGBtoLAB(this.redDouble, this.greenDouble, this.blueDouble);
        this._lab_lightness = lab[0];
        this._lab_a = lab[1];
        this._lab_b = lab[2];

        lab = null;
    }

    void _updateRGBfromLAB() {
        this._lab_dirty = false;

        List<double> rgb = LABtoRGB(this._lab_lightness, this._lab_a, this._lab_b);

        this.redDouble = rgb[0];
        this.greenDouble = rgb[1];
        this.blueDouble = rgb[2];

        rgb = null;
    }

    // Operators ###################################################################################

    @override
    bool operator ==(dynamic other) {
        if (other is Colour) {
            return this._red == other._red && this._green == other._green && this._blue == other._blue && this._alpha == other._alpha;
        }
        return false;
    }

    @override
    int get hashCode => this.toHex(true);

    Colour operator +(dynamic other) {
        if (other is Colour) {
            return new Colour(this.red + other.red, this.green + other.green, this.blue + other.blue, this.alpha + other.alpha);
        } else if (other is num) {
            return new Colour.double(this.redDouble + other, this.greenDouble + other, this.blueDouble + other, this.alphaDouble);
        } /*else if (other is int) {
            return new Colour(this.red + other, this.green + other, this.blue + other, this.alpha);
        }*/
        throw Exception("Cannot add [${other.runtimeType} $other] to a Colour. Only Colour, double and int are valid.");
    }

    Colour operator -(dynamic other) {
        if (other is Colour) {
            return new Colour(this.red - other.red, this.green - other.green, this.blue - other.blue, this.alpha - other.alpha);
        } else if (other is num) {
            return new Colour.double(this.redDouble - other, this.greenDouble - other, this.blueDouble - other, this.alphaDouble);
        }/* else if (other is int) {
            return new Colour(this.red - other, this.green - other, this.blue - other, this.alpha);
        }*/
        throw Exception("Cannot subtract [${other.runtimeType} $other] from a Colour. Only Colour, double and int are valid.");
    }

    Colour operator /(dynamic other) {
        if (other is Colour) {
            return new Colour.double(this.redDouble / other.redDouble, this.greenDouble / other.greenDouble, this.blueDouble / other.blueDouble, this.alphaDouble / other.alphaDouble);
        } else if (other is num) {
            return new Colour.double(this.redDouble / other, this.greenDouble / other, this.blueDouble / other, this.alphaDouble);
        }
        throw Exception("Cannot divide a Colour by [${other.runtimeType} $other]. Only Colour, double and int are valid.");
    }

    Colour operator *(dynamic other) {
        if (other is Colour) {
            return new Colour.double(this.redDouble * other.redDouble, this.greenDouble * other.greenDouble, this.blueDouble * other.blueDouble, this.alphaDouble * other.alphaDouble);
        } else if (other is num) {
            return new Colour.double(this.redDouble * other, this.greenDouble * other, this.blueDouble * other, this.alphaDouble);
        }
        throw Exception("Cannot multiply a Colour by [${other.runtimeType} $other]. Only Colour, double and int are valid.");
    }

    int operator [](int index) {
        if (index == 0) return red;
        if (index == 1) return green;
        if (index == 2) return blue;
        if (index == 3) return alpha;
        throw Exception("Colour index out of range: $index");
    }

    void operator []=(int index, num value) {
        if (index < 0 || index > 3) { throw Exception("Colour index out of range: $index"); }
        if (value is int) {
            if (index == 0) {
                this.red = value;
            } else if (index == 1) {
                this.green = value;
            } else if (index == 2) {
                this.blue = value;
            } else {
                this.alpha = value;
            }
        } else {
            if (index == 0) {
                this.redDouble = value;
            } else if (index == 1) {
                this.greenDouble = value;
            } else if (index == 2) {
                this.blueDouble = value;
            } else {
                this.alphaDouble = value;
            }
        }
    }

    // Static conversions ###################################################################################

    static List<double> RGBtoHSV(double r, double g, double b) {
        final double maximum = max(max(r,g),b);
        final double minimum = min(min(r,g),b);

        final double v = maximum;
        final double delta = maximum-minimum;

        final double s = maximum == 0.0 ? 0.0 : delta / maximum;

        double h;

        if (maximum == minimum) {
            h = 0.0;
        } else {
            if (maximum == r) {
                h = (g - b) / delta + (g < b ? 6 : 0);
            } else if (maximum == g) {
                h = (b - r) / delta + 2;
            } else {
                h = (r - g) / delta + 4;
            }

            h /= 6.0;
        }

        return <double>[h,s,v];
    }

    static List<double> HSVtoRGB(double h, double s, double v) {
        double r,g,b;

        final int i = (h*6).floor();
        final double f = h * 6 - i;
        final double p = v * (1-s);
        final double q = v * (1-f*s);
        final double t = v * (1-(1-f)*s);

        final int sec = i % 6;

        if (sec == 0) {
            r = v;
            g = t;
            b = p;
        } else if (sec == 1) {
            r = q;
            g = v;
            b = p;
        } else if (sec == 2) {
            r = p;
            g = v;
            b = t;
        } else if (sec == 3) {
            r = p;
            g = q;
            b = v;
        } else if (sec == 4) {
            r = t;
            g = p;
            b = v;
        } else {
            r = v;
            g = p;
            b = q;
        }

        return <double>[r,g,b];
    }

    static List<double> RGBtoLAB(double r, double g, double b) {
        final List<double> xyz = RGBtoXYZ(r,g,b);
        return XYZtoLAB(xyz[0], xyz[1], xyz[2]);
    }

    static List<double> RGBtoXYZ(double r, double g, double b) {
        r = (r > 0.04045 ? pow((r + 0.055) / 1.055, 2.4) : r / 12.92) * 100.0;
        g = (g > 0.04045 ? pow((g + 0.055) / 1.055, 2.4) : g / 12.92) * 100.0;
        b = (b > 0.04045 ? pow((b + 0.055) / 1.055, 2.4) : b / 12.92) * 100.0;

        return <double>[
            r * 0.4124 + g * 0.3576 + b * 0.1805,
            r * 0.2126 + g * 0.7152 + b * 0.0722,
            r * 0.0193 + g * 0.1192 + b * 0.9505
        ];
    }

    static List<double> XYZtoLAB(double x, double y, double z) {
        x /= referenceWhite[0];
        y /= referenceWhite[1];
        z /= referenceWhite[2];

        x = x > xyzEpsilon ? pow(x, 1/3.0) : (xyzKappa * x + 16) / 116.0;
        y = y > xyzEpsilon ? pow(y, 1/3.0) : (xyzKappa * y + 16) / 116.0;
        z = z > xyzEpsilon ? pow(z, 1/3.0) : (xyzKappa * z + 16) / 116.0;

        return <double>[max(0.0, 116 * y - 16), 500 * (x - y), 200 * (y - z)];
    }

    static List<double> LABtoRGB(double lab_l, double lab_a, double lab_b) {
        final List<double> xyz = LABtoXYZ(lab_l, lab_a, lab_b);
        return XYZtoRGB(xyz[0], xyz[1], xyz[2]);
    }

    static List<double> XYZtoRGB(double x, double y, double z) {
        double r,g,b;

        x /= 100.0;
        y /= 100.0;
        z /= 100.0;

        r = x *  3.2406 + y * -1.5372 + z * -0.4986;
        g = x * -0.9689 + y *  1.8758 + z *  0.0415;
        b = x *  0.0557 + y * -0.2040 + z *  1.0570;

        r = r > 0.0031308 ? 1.055 * pow(r, 1/2.4) - 0.055 : 12.92 * r;
        g = g > 0.0031308 ? 1.055 * pow(g, 1/2.4) - 0.055 : 12.92 * g;
        b = b > 0.0031308 ? 1.055 * pow(b, 1/2.4) - 0.055 : 12.92 * b;

        return <double>[r,g,b];
    }

    static List<double> LABtoXYZ(double l, double a, double b) {
        double x,y,z;

        y = (l + 16) / 116.0;
        x = a / 500.0 + y;
        z = y - b / 200.0;

        final double x3 = x * x * x;
        final double z3 = z * z * z;
        return <double>[
            referenceWhite[0] * (x3 > xyzEpsilon ? x3 : (x - 16 / 116.0) / 7.787),
            referenceWhite[1] * (l > (xyzKappa * xyzEpsilon) ? pow(((l + 16) / 116.0), 3): l / xyzKappa),
            referenceWhite[2] * (z3 > xyzEpsilon ? z3 : (x - 16 / 116.0) / 7.787)
        ];
    }
}