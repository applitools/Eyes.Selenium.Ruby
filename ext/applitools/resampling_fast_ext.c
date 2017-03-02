#include "resampling_fast_ext.h"

void Init_resampling_fast() {
  VALUE Applitools = rb_define_module("Applitools");
  VALUE Resampling = rb_define_module_under(Applitools, "ResamplingFast");
  rb_define_method(Resampling, "interpolate_cubic", c_interpolate_cubic, 1);
  rb_define_method(Resampling, "merge_pixels", c_merge_pixels, 1);
};


VALUE c_interpolate_cubic(VALUE self, VALUE data) {
  double t = NUM2DBL(rb_ary_entry(data, 1));
  BYTE  new_r, new_g, new_b, new_a;
  VALUE p0, p1, p2, p3;

  p0 = NUM2UINT(rb_ary_entry(data, 2));
  p1 = NUM2UINT(rb_ary_entry(data, 3));
  p2 = NUM2UINT(rb_ary_entry(data, 4));
  p3 = NUM2UINT(rb_ary_entry(data, 5));

  new_r = interpolate_char(t, R_BYTE(p0), R_BYTE(p1), R_BYTE(p2), R_BYTE(p3));
  new_g = interpolate_char(t, G_BYTE(p0), G_BYTE(p1), G_BYTE(p2), G_BYTE(p3));
  new_b = interpolate_char(t, B_BYTE(p0), B_BYTE(p1), B_BYTE(p2), B_BYTE(p3));
  new_a = interpolate_char(t, A_BYTE(p0), A_BYTE(p1), A_BYTE(p2), A_BYTE(p3));

  return UINT2NUM(BUILD_PIXEL(new_r, new_g, new_b, new_a));
};

BYTE interpolate_char(double t, BYTE c0, BYTE c1, BYTE c2, BYTE c3) {
  double a, b, c, d, res;
  a = - 0.5 * c0 + 1.5 * c1 - 1.5 * c2 + 0.5 * c3;
  b = c0 - 2.5 * c1 + 2 * c2 - 0.5 * c3;
  c = 0.5 * c2 - 0.5 * c0;
  d = c1;
  res = a * t * t * t + b * t * t + c * t + d + 0.5;
  if(res < 0) {
    res = 0;
  } else if(res > 255) {
    res = 255;
  };
  return (BYTE)(res);
};

VALUE c_merge_pixels(VALUE self, VALUE pixels) {
  unsigned int i, size, real_colors, acum_r, acum_g, acum_b, acum_a;
  BYTE new_r, new_g, new_b, new_a;
  PIXEL pix;

  acum_r = 0;
  acum_g = 0;
  acum_b = 0;
  acum_a = 0;

  new_r = 0;
  new_g = 0;
  new_b = 0;
  new_a = 0;

  size = NUM2UINT(rb_funcall(pixels, rb_intern("size"), 0, Qnil)) - 1;
  real_colors = 0;

  for(i=1; i < size; i++) {
    pix = NUM2UINT(rb_ary_entry(pixels, i));
    if(A_BYTE(pix) != 0) {
      acum_r += R_BYTE(pix);
      acum_g += G_BYTE(pix);
      acum_b += B_BYTE(pix);
      acum_a += A_BYTE(pix);
      real_colors += 1;
    }
  }

  if(real_colors > 0) {
    new_r = (BYTE)(acum_r/real_colors + 0.5);
    new_g = (BYTE)(acum_g/real_colors + 0.5);
    new_b = (BYTE)(acum_b/real_colors + 0.5);
  }
  new_a = (BYTE)(acum_a/(size - 1) + 0.5);
  return UINT2NUM(BUILD_PIXEL(new_r, new_g, new_b, new_a));
}
