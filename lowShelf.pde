class lowShelf implements AudioEffect
{
  float b0, b1, b2, a0, a1, a2;
  float[] lx = new float[2];
  float[] ly = new float[2];
  float[] rx = new float[2];
  float[] ry = new float[2];

  lowShelf(float fs, float f, float g)
  {
    lx[0] = 0.0;
    lx[1] = 0.0;
    ly[0] = 0.0;
    ly[1] = 0.0;
    rx[0] = 0.0;
    rx[1] = 0.0;
    ry[0] = 0.0;
    ry[1] = 0.0;
    float omega = 2.0 * 3.141592 * ( f / fs );
    float sn = sin(omega);
    float cs = cos(omega);

    float fQ = 1.0 / 1.41421356;
    float A = pow(10.0, g / 40.0);
    float a = sn / (2.0 * fQ);
    float b = sqrt(A / fQ);

    b0 = A * ( ( A + 1.0 ) - ( A - 1.0 ) * cs + b * sn );
    b1 = 2.0 * A * ( ( A - 1.0 ) - ( A + 1.0 ) * cs );
    b2 = A * ( ( A + 1.0 ) - ( A - 1.0 ) * cs - b * sn );
    a0 = (( A + 1.0 ) + ( A - 1.0 ) * cs + b * sn );
    a1 = -2.0 * ( ( A - 1.0 ) + ( A + 1.0 ) * cs );
    a2 = (( A + 1.0 ) + ( A - 1.0 ) * cs - b * sn );
  }

  void biquad_process(float[] samp, float[] x, float[] y)
  {
    float[] out = new float[samp.length];
    out[0] = ( b0 / a0 ) * samp[0] +
      ( b1 / a0 ) * x[1] +
      ( b2 / a0 ) * x[0] -
      ( a1 / a0 ) * y[1] -
      ( a2 / a0 ) * y[0];

    out[1] = ( b0 / a0 ) * samp[1] +
      ( b1 / a0 ) * samp[0] +
      ( b2 / a0 ) * x[1] -
      ( a1 / a0 ) * out[0] -
      ( a2 / a0 ) * y[1];
    for ( int n = 2; n < samp.length; n++ )
    {
      out[n] = ( b0 / a0 ) * samp[n] +
        ( b1 / a0 ) * samp[n-1] +
        ( b2 / a0 ) * samp[n-2] -
        ( a1 / a0 ) * out[n-1] -
        ( a2 / a0 ) * out[n-2];
    }

    x[0] = samp[samp.length - 2];
    x[1] = samp[samp.length - 1];
    y[0] = out[out.length - 2];
    y[1] = out[out.length - 1];

    arraycopy(out, samp);
  }

  void process(float[] samp)
  {
    biquad_process(samp, lx, ly);
  }
  void process(float[] left, float[] right)
  {
    biquad_process(left, lx, ly);
    biquad_process(right, rx, ry);
  }
}
