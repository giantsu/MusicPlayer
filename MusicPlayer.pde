import processing.opengl.*;
import javax.media.opengl.GL; 

import ddf.minim.analysis.*;
import ddf.minim.*;

int BUFSIZE = 512;

Minim minim;

AudioPlayer player;

AudioMetaData meta;

String music;

int number;

int number2;

int number3;

int number4;

int count;

PFont font;

int m;
int s;
int n = 0;
int m2;
int s2;

float el = 600 - (600 / 5 * 3 - 600 / 5);

float gainY = (float)(600 / 5 + 4 * (el / 8));
float e32Y = (float)(600 / 5 + 4 * (el / 8));
float e64Y = (float)(600 / 5 + 4 * (el / 8));
float e128Y = (float)(600 / 5 + 4 * (el / 8));
float e256Y = (float)(600 / 5 + 4 * (el / 8));
float e512Y = (float)(600 / 5 + 4 * (el / 8));
float e1KY = (float)(600 / 5 + 4 * (el / 8));
float e2KY = (float)(600 / 5 + 4 * (el / 8));
float e4KY = (float)(600 / 5 + 4 * (el / 8));
float e8KY = (float)(600 / 5 + 4 * (el / 8));
float e16KY = (float)(600 / 5 + 4 * (el / 8));

float gain;

float FS = 44100.0;
float LF;
float LGAIN;
float HF;
float HGAIN;

lowShelf bass32;
highShelf high32;
lowShelf bass64;
highShelf high64;
lowShelf bass128;
highShelf high128;
lowShelf bass256;
highShelf high256;
lowShelf bass512;
highShelf high512;
lowShelf bass1K;
highShelf high1K;
lowShelf bass2K;
highShelf high2K;
lowShelf bass4K;
highShelf high4K;
lowShelf bass8K;
highShelf high8K;
lowShelf bass16K;
highShelf high16K;

PeakingFilter eq32;
PeakingFilter eq64;
PeakingFilter eq128;
PeakingFilter eq256;
PeakingFilter eq512;
PeakingFilter eq1K;
PeakingFilter eq2K;
PeakingFilter eq4K;
PeakingFilter eq8K;
PeakingFilter eq16K;

FFT fft;

GL gl;

float[] posX = new float[BUFSIZE];
float[] posY = new float[BUFSIZE];
float[] speedX = new float[BUFSIZE];
float[] speedY = new float[BUFSIZE];
float[] angle = new float[BUFSIZE];

// バネの硬さ
float stiffness = 0.4;

// バネの摩擦係数（減衰の程度）
float damping = 0.9;

// 円の重さ
float mass = 12.0;

void setup() {
  size(900, 600, OPENGL);

  frameRate(40);

  colorMode(HSB, 360, 100, 100, 100);

  noStroke();

  // OpenGL
  gl=((PGraphicsOpenGL)g).gl;
  gl.setSwapInterval(1);

  minim = new Minim(this);

  if (number % 2 == 0) {
    music = SoundSelect(0);
  }
  else if (number % 2 != 0) {
    music = SoundSelect(1);
  }

  player = minim.loadFile(music, 512);

  meta = player.getMetaData();
  font = loadFont("AgencyFB-Reg-36.vlw");
  textFont(font, 24); 

  fft = new FFT(player.bufferSize(), player.sampleRate());

  for (int i = 0; i < BUFSIZE; i++) {
    posX[i] = 0;
    posY[i] = 0;
    speedX[i] = 0;
    speedY[i] = 0;
    angle[i] = radians(random(0, 360));
  }

  background(0);
}

void draw() {
  // 曲の情報(メタデータ)を表示
  textAlign(LEFT);
  fill(360, 100, 100);
  text("Title:" + meta.title(), 5, 50);
  text("Artist:" + meta.author(), 5, 50+60);
  text("Album:" + meta.album(), 5, 50+2*60);

  // シークバーの表示
  float x = map(player.position(), 0, player.length(), 0+2, width-10);
  drawBar(x);

  // 枠
  noFill();
  stroke(360, 0, 40, 100);
  strokeWeight(5);
  rect(0, 568, 900, 30);

  // 時間表示
  fill(41, 100, 100);
  int rf = player.position()/1000;
  m = rf / 60;
  s = rf - m * 60;
  if (s < 10) {
    String s0 = "0" + s;
    text(m + ":" + s0, 795, 593);
  }
  else {
    text(m + ":" + s, 795, 593);
  }

  text(" / ", 830, 593);

  int sf = meta.length()/1000;
  m2 = sf / 60;
  s2 = sf - m2 * 60 -1;
  if (s2 < 10) {
    String ss = "0" + s2;
    text(m2 + ":" + ss, 855, 593);
  }
  else {
    text(m2 + ":" + s2, 855, 593);
  }

  backgroundFade();

  if (number2 == 0) {
    //加算合成
    gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE);
  }
  else if (number2 == 1) {
    //反転合成
    gl.glBlendFunc(GL.GL_ONE_MINUS_DST_COLOR, GL.GL_ZERO);
  }
  else if (number2 == 2) {
    //通常転送
    gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
  }

  fft.forward(player.mix);

  float specSize = fft.specSize();
  float getBand;

  if (number3 == 0) {
    translate(width/2, height/2-34);

    for (int i = 0; i < specSize; i++) {
      getBand = fft.getBand(i);

      // 音量に基づいてバネにかかる力
      float addFroce = getBand * i * width/float(BUFSIZE)/2.0;
      // 外側に向かう方向（角度）をランダム
      float direction = radians(random(0, 360));
      // 力と角度に基づいて、円の中心位置を取得
      float addX = cos(direction) * addFroce;
      float addY = sin(direction) * addFroce;

      float forceX = stiffness * -posX[i] + addX;
      float accelerationX = forceX / mass;
      speedX[i] = damping * (speedX[i] + accelerationX);
      float forceY = stiffness * -posY[i] + addY;
      float accelerationY = forceY / mass;
      speedY[i] = damping * (speedY[i] + accelerationY);
      posX[i] += speedX[i];
      posY[i] += speedY[i];

      fill(255, 10);
      float h = map(i, 0, specSize, 0, 360);
      float r = getBand * i / 4.0 + 30.0;
      fill(h, 100, 100, 10);
      ellipse(posX[i], posY[i], r, r);
    }
  }

  else if (number3 == 1) {
    for (int i = 0; i < specSize; i++) {
      float h = map(i, 0, specSize, 0, width);
      stroke(h, 100, 100, 100);
      float xx = map(i, 0, specSize, 0, width);
      line(xx, height-34, xx, height-34 - fft.getBand(i) * 12);
    }
  }

  else if (number3 == 2) {
    // FFT 実行（左チャンネル）
    fft.forward(player.left);
    for (int i = 0; i < specSize; i++) {
      float h = map(i, 0, specSize, 0, 360);
      float a = map(fft.getBand(i), 0, BUFSIZE/16, 0, 255);
      float xx = map(i, 0, specSize, width/2, 0);
      float w = width / specSize / 2;
      fill(h, 80, 80, a);
      rect(xx, 0, w, height-34);
    }

    // FFT 実行（右チャンネル）
    fft.forward(player.right);
    for (int i = 0; i < specSize; i++) {
      float h = map(i, 0, specSize, 0, 360);
      float a = map(fft.getBand(i), 0, BUFSIZE/16, 0, 255);
      float xx = map(i, 0, specSize, width/2, width);
      float w = width / specSize / 2;

      fill(h, 80, 80, a);
      rect(xx, 0, w, height-34);
    }
  }
  else if (number3 == 3) {
    background(0);
    number2 = 2;
    equalizer();
  }
}

void stop() {
  player.close();
  minim.stop();
  super.stop();
}

void backgroundFade() {
  // OpenGL を利用して減色混合
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
  gl.glBlendEquation(GL.GL_FUNC_ADD);

  noStroke();
  fill(0, 10);
  rect(0, 0, width, height);
}

void keyPressed() {
  if (key == ' ') {
    if (player.isPlaying()) {
      player.pause();
    }
    else if (!player.isPlaying()) {
      if (count == 0) {
        if (gain != 0) {
          player.setGain(gain);
        }
        if (eq32 != null) {
          player.addEffect(eq32);
        }
        if (eq64 != null) {
          player.addEffect(eq64);
        }
        if (eq128 != null) {
          player.addEffect(eq128);
        }
        if (eq256 != null) {
          player.addEffect(eq256);
        }
        if (eq512 != null) {
          player.addEffect(eq512);
        }
        if (eq1K != null) {
          player.addEffect(eq1K);
        }
        if (eq2K != null) {
          player.addEffect(eq2K);
        }
        if (eq4K != null) {
          player.addEffect(eq4K);
        }
        if (eq8K != null) {
          player.addEffect(eq8K);
        }
        if (eq16K != null) {
          player.addEffect(eq16K);
        }
        count++;
      }
      player.play();
    }
  }
  else if (key == 'c') {
    colorMode(HSB, 360, 100, 100, 20);
  }
  else if (key == 'v') {
    colorMode(HSB, 360, 100, 100, 100);
  }
  else if (key == '1') {
    frameRate(10);
  }
  else if (key == '2') {
    frameRate(20);
  }
  else if (key == '3') {
    frameRate(30);
  }
  else if (key == '4') {
    frameRate(40);
  }
  else if (key == '5') {
    frameRate(50);
  }
  else if (key == '6') {
    frameRate(60);
  }
  else if (key == '7') {
    frameRate(70);
  }
  else if (key == '8') {
    frameRate(80);
  }
  else if (key == '9') {
    frameRate(90);
  }
  else if (key == 'z') {
    number2 = 1;
  }
  else if (key == 'x') {
    number2 = 0;
  }
  else if (key == 'm') {
    number2 = 2;
  }
  else if (key == 'q') {
    number3 = 0;
  }
  else if (key == 'w') {
    number3 = 1;
  }
  else if (key == 'e') {
    number3 = 2;
  }
  else if (key == 'r') {
    number3 = 3;
  }
}

void mousePressed() {
  if (mouseButton == RIGHT) {
    count = 0;
    number++;
    player.close();
    setup();
  }
}

String SoundSelect(int i) {
  if (i % 2 == 0) {
    return "He's A Pirate.mp3";
  }
  else {
    return "Blinded By Light.mp3";
  }
}

void drawBar(float x) {
  noStroke();
  fill(360, 100, 100, 100);
  rect(0, 570, x, 27);
  fill(0, 0, 100, 100);
  rect(x, 570, 10, 27);
}

void mouseDragged() {
  float x = mouseX;
  float y = mouseY;
  if (mouseButton == LEFT) {
    if (number3 == 0 || number3 == 1 || number3 == 2) {
      if (y >= 570) {
        player.pause();
        drawBar(x);
        float xx = map(mouseX, 0, width-10, 0, player.length());
        int X = (int)xx;
        player.cue(X);
      }
    }
    if (number3 == 3) {
      if (y > height / 5 && y < height / 5 + height / 5 * 3) {
        if (x > width / 10 - 5 && x < width / 10 + width / 85 + 5) {
          number4 = 0;
          //gainY = mouseY;
        }
        else if (x > width / 3 + 0 * 50 - 5 && x < width / 3 + 0 * 50 + width / 85 + 5) {
          number4 = 1;
          //e32Y = mouseY;
        }
        else if (x > width / 3 + 1 * 50 - 5 && x < width / 3 + 1 * 50 + width / 85 + 5) {
          number4 = 2;
          //e64Y = mouseY;
        }
        else if (x > width / 3 + 2 * 50 - 5 && x < width / 3 + 2 * 50 + width / 85 + 5) {
          number4 = 3;
          //e128Y = mouseY;
        }
        else if (x > width / 3 + 3 * 50 - 5 && x < width / 3 + 3 * 50 + width / 85 + 5) {
          number4 = 4;
          //e256Y = mouseY;
        }
        else if (x > width / 3 + 4 * 50 - 5 && x < width / 3 + 4 * 50 + width / 85 + 5) {
          number4 = 5;
          //e512Y = mouseY;
        }
        else if (x > width / 3 + 5 * 50 - 5 && x < width / 3 + 5 * 50 + width / 85 + 5) {
          number4 = 6;
          //e1KY = mouseY;
        }
        else if (x > width / 3 + 6 * 50 - 5 && x < width / 3 + 6 * 50 + width / 85 + 5) {
          number4 = 7;
          //e2KY = mouseY;
        }
        else if (x > width / 3 + 7 * 50 - 5 && x < width / 3 + 7 * 50 + width / 85 + 5) {
          number4 = 8;
          //e4KY = mouseY;
        }
        else if (x > width / 3 + 8 * 50 - 5 && x < width / 3 + 8 * 50 + width / 85 + 5) {
          number4 = 9;
          //e8KY = mouseY;
        }
        else if (x > width / 3 + 9 * 50 - 5 && x < width / 3 + 9 * 50 + width / 85 + 5) {
          number4 = 10;
          //e16KY = mouseY;
        }
        if (number4 == 0) {
          gainY = mouseY;
          gain = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            gain = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            gain = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }
          player.setGain(gain);
          println(player.gain());
        }
        if (number4 == 1) {
          e32Y = mouseY;
          float h = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }

          /*player.disableEffect(bass32);
           player.disableEffect(high32);*/
          player.disableEffect(eq32);

          /*bass32 = new lowShelf(FS, 32, h);
           high32 = new highShelf(FS, 32, h);
           player.addEffect(bass32);
           player.addEffect(high32);*/
          eq32 = new PeakingFilter(FS, 32, h);
          player.addEffect(eq32);

          /*for (int i = 0; i < 32 + 32 / 2; i++) {
           println(i + " : " + fft.getFreq(i));
           //fft.setFreq(i, fft.getFreq(i) * sqrt(pow(10, h / 10)));
           println(i + " : " + fft.getFreq(i));
           }*/
        }
        if (number4 == 2) {
          e64Y = mouseY;
          float h = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }

          /*player.disableEffect(bass64);
           player.disableEffect(high64);*/
          player.disableEffect(eq64);
          eq64 = new PeakingFilter(FS, 64, h);
          player.addEffect(eq64);

          /*bass64 = new lowShelf(FS, 64, h);
           high64 = new highShelf(FS, 64, h);
           player.addEffect(bass64);
           player.addEffect(high64);*/

          /*for (int i = 32 + 32 / 2; i < 64 + 64 / 2; i++) {
           fft.setFreq(i, fft.getFreq(i) * sqrt(pow(10, h / 10)));
           }*/
          println(fft.getFreq(64));
        }
        if (number4 == 3) {
          e128Y = mouseY;
          float h = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }

          /*player.disableEffect(bass128);
           player.disableEffect(high128);*/
          player.disableEffect(eq128);
          eq128 = new PeakingFilter(FS, 128, h);
          player.addEffect(eq128);

          /*bass128 = new lowShelf(FS, 128, h);
           high128 = new highShelf(FS, 128, h);
           player.addEffect(bass128);
           player.addEffect(high128);*/

          /*for (int i = 64 + 64 / 2; i < 128 + 128 / 2; i++) {
           fft.setFreq(i, fft.getFreq(i) * sqrt(pow(10, h / 10)));
           }*/
          println(fft.getFreq(128));
        }
        if (number4 == 4) {
          e256Y = mouseY;
          float h = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }

          /*player.disableEffect(bass256);
           player.disableEffect(high256);*/
          player.disableEffect(eq256);
          eq256 = new PeakingFilter(FS, 256, h);
          player.addEffect(eq256);

          /*bass256 = new lowShelf(FS, 256, h);
           high256 = new highShelf(FS, 256, h);
           player.addEffect(bass256);
           player.addEffect(high256);*/

          /*for (int i = 128 + 128 / 2; i < 256 + 256 / 2; i++) {
           fft.setFreq(i, fft.getFreq(i) * sqrt(pow(10, h / 10)));
           }*/
          println(fft.getFreq(256));
        }
        if (number4 == 5) {
          e512Y = mouseY;
          float h = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }

          /*player.disableEffect(bass512);
           player.disableEffect(high512);*/
          player.disableEffect(eq512);
          eq512 = new PeakingFilter(FS, 512, h);
          player.addEffect(eq512);

          /*bass512 = new lowShelf(FS, 512, h);
           high512 = new highShelf(FS, 512, h);
           player.addEffect(bass512);
           player.addEffect(high512);*/

          /*for (int i = 256 + 256 / 2; i < 512 + 512 / 2; i++) {
           fft.setFreq(i, fft.getFreq(i) * sqrt(pow(10, h / 10)));
           }*/
          println(fft.getFreq(512));
        }
        if (number4 == 6) {
          e1KY = mouseY;
          float h = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }

          /*player.disableEffect(bass1K);
           player.disableEffect(high1K);*/
          player.disableEffect(eq1K);
          eq1K = new PeakingFilter(FS, 1024, h);
          player.addEffect(eq1K);

          /*bass1K = new lowShelf(FS, 1024, h);
           high1K = new highShelf(FS, 1024, h);
           player.addEffect(bass1K);
           player.addEffect(high1K);*/

          /*for (int i = 512 + 512 / 2; i < 1024 + 1024 / 2; i++) {
           fft.setFreq(i, fft.getFreq(i) * sqrt(pow(10, h / 10)));
           }*/
          println(fft.getFreq(1024));
        }
        if (number4 == 7) {
          e2KY = mouseY;
          float h = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }

          /*player.disableEffect(bass2K);
           player.disableEffect(high2K);*/
          player.disableEffect(eq2K);
          eq2K = new PeakingFilter(FS, 2048, h);
          player.addEffect(eq2K);

          /*bass2K = new lowShelf(FS, 2048, h);
           high2K = new highShelf(FS, 2048, h);
           player.addEffect(bass2K);
           player.addEffect(high2K);*/

          /*for (int i = 1024 + 1024 / 2; i < 2048 + 2048 / 2; i++) {
           fft.setFreq(i, fft.getFreq(i) * sqrt(pow(10, h / 10)));
           }*/
          println(fft.getFreq(2048));
        }
        if (number4 == 8) {
          e4KY = mouseY;
          float h = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }

          /*player.disableEffect(bass4K);
           player.disableEffect(high4K);*/
          player.disableEffect(eq4K);
          eq4K = new PeakingFilter(FS, 4096, h);
          player.addEffect(eq4K);

          /*bass4K = new lowShelf(FS, 4096, h);
           high4K = new highShelf(FS, 4096, h);
           player.addEffect(bass4K);
           player.addEffect(high4K);*/

          /*for (int i = 2048 + 2048 / 2; i < 4096 + 4096 / 2; i++) {
           fft.setFreq(i, fft.getFreq(i) * sqrt(pow(10, h / 10)));
           }*/
          println(fft.getFreq(4096));
        }
        if (number4 == 9) {
          e8KY = mouseY;
          float h = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }

          /*player.disableEffect(bass8K);
           player.disableEffect(high8K);*/
          player.disableEffect(eq8K);
          eq8K = new PeakingFilter(FS, 8192, h);
          player.addEffect(eq8K);

          /*bass8K = new lowShelf(FS, 8192, h);
           high8K = new highShelf(FS, 8192, h);
           player.addEffect(bass8K);
           player.addEffect(high8K);*/

          /*for (int i = 4096 + 4096 / 2; i < 8192 + 8192 / 2; i++) {
           fft.setFreq(i, fft.getFreq(i) * sqrt(pow(10, h / 10)));
           }*/
          println(fft.getFreq(8192));
        }
        if (number4 == 10) {
          e16KY = mouseY;
          float h = 0;
          if (mouseY < (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(height / 5), (float)(600 / 5 + 4 * (el / 8)), 12.0, 0.0);
          }
          else if (mouseY > (float)(600 / 5 + 4 * (el / 8))) {
            h = map(mouseY, (float)(600 / 5 + 4 * (el / 8)), height / 5 + height / 5 * 3, 0.0, -12.0);
          }

          /*player.disableEffect(bass16K);
           player.disableEffect(high16K);*/
          player.disableEffect(eq16K);
          eq16K = new PeakingFilter(FS, 16384, h);
          player.addEffect(eq16K);

          /*bass16K = new lowShelf(FS, 16384, h);
           high16K = new highShelf(FS, 16384, h);
           player.addEffect(bass16K);
           player.addEffect(high16K);*/

          /*for (int i = 8192 + 8192 / 2; i < 16384 + 16384 / 2; i++) {
           fft.setFreq(i, fft.getFreq(i) * sqrt(pow(10, h / 10)));
           }*/
          println(fft.getFreq(16384));
        }
      }
    }
  }
}

void mouseReleased() {
  float x = mouseX;
  float y = mouseY;
  if (number3 == 0 || number3 == 1 || number3 == 2) {
    if (y >= 570) {
      if (mouseButton == LEFT) {
        if (count == 0) {
          if (gain != 0) {
            player.setGain(gain);
          }
          if (eq32 != null) {
            player.addEffect(eq32);
          }
          if (eq64 != null) {
            player.addEffect(eq64);
          }
          if (eq128 != null) {
            player.addEffect(eq128);
          }
          if (eq256 != null) {
            player.addEffect(eq256);
          }
          if (eq512 != null) {
            player.addEffect(eq512);
          }
          if (eq1K != null) {
            player.addEffect(eq1K);
          }
          if (eq2K != null) {
            player.addEffect(eq2K);
          }
          if (eq4K != null) {
            player.addEffect(eq4K);
          }
          if (eq8K != null) {
            player.addEffect(eq8K);
          }
          if (eq16K != null) {
            player.addEffect(eq16K);
          }
          count++;
        }
        player.play();
      }
    }
  }
}

void equalizer() {
  float l = height - (height / 5 * 3 - height / 5); //l = 360
  strokeWeight(0.5);
  stroke(180, 100, 100, 50);
  for (int i = 1; i < 8; i++) {
    line(width / 10 - 20, (float)(height / 5 + i * (l / 8)), width / 10 + width / 85 + 20, (float)(height / 5 + i * (l / 8)));
    line(width / 3 - 20, (float)(height / 5 + i * (l / 8)), width / 3 + 9 * 50 + width / 85 + 20, (float)(height / 5 + i * (l / 8)));
  }

  stroke(360, 0, 40, 100);
  strokeWeight(3);
  //strokeJoin(ROUND);
  textAlign(CENTER);
  int n = 32;

  fill(0, 0, 0);
  rect(width / 10, height / 5, width / 85, height / 5 * 3);
  fill(360, 0, 40, 100);
  text("GAIN", width / 10 + 3, height / 5 * 4.5);
  for (int i = 0; i < 10; i++) {
    fill(0, 0, 0);
    rect(width / 3 + i * 50, height / 5, width / 85, height / 5 * 3);
    fill(360, 0, 40, 100);
    if (n < 1000) {
      text(n, width / 3 + i * 50 + 5, height / 5 * 4.5);
    }
    else if (n > 1000) {
      text(n / 1000 + "K", width / 3 + i * 50 + 5, height / 5 * 4.5);
    }
    n = n * 2;
  }

  int hel = 12;
  for (int i = 0; i < 9; i++) {
    if (hel > 0) {
      text("+" + hel + "dB", (width / 3 - width / 10) - 10, (float)(height / 5 + i * (l / 8) + 10));
    }
    else if (hel <= 0) {
      text(hel + "dB", (width / 3 - width / 10) - 10, (float)(height / 5 + i * (l / 8) + 10));
    }
    hel = hel - 3;
  }

  rectMode(CENTER);
  rect(width / 10 + (float)((width / 85) / 2), gainY, 20, 40);
  rect(width / 3 + 0 * 50 + (float)((width / 85) / 2), e32Y, 20, 40);
  rect(width / 3 + 1 * 50 + (float)((width / 85) / 2), e64Y, 20, 40);
  rect(width / 3 + 2 * 50 + (float)((width / 85) / 2), e128Y, 20, 40);
  rect(width / 3 + 3 * 50 + (float)((width / 85) / 2), e256Y, 20, 40);
  rect(width / 3 + 4 * 50 + (float)((width / 85) / 2), e512Y, 20, 40);
  rect(width / 3 + 5 * 50 + (float)((width / 85) / 2), e1KY, 20, 40);
  rect(width / 3 + 6 * 50 + (float)((width / 85) / 2), e2KY, 20, 40);
  rect(width / 3 + 7 * 50 + (float)((width / 85) / 2), e4KY, 20, 40);
  rect(width / 3 + 8 * 50 + (float)((width / 85) / 2), e8KY, 20, 40);
  rect(width / 3 + 9 * 50 + (float)((width / 85) / 2), e16KY, 20, 40);

  rectMode(CORNER);
}

