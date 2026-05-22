return {
  black = 0xff181819,
  white = 0xffd3c6aa,
  red = 0xffd66a6c,
  green = 0xff9ed072,
  blue = 0xff76cce0,
  yellow = 0xffe7c664,
  orange = 0xfff39660,
  magenta = 0xffb39df3,
  grey = 0xff9da9a0,
  cyan = 0xff34a77c,
  transparent = 0x00000000,

  bar = {
    bg = 0xff2a3135,
    border = 0xff2c2e34,
  },
  popup = {
    bg = 0xc02c2e34,
    border = 0xff7f8490
  },
  bg1 = 0xff3d484d,
  bg2 = 0xff343f44,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then return color end
    return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
  end,
}
