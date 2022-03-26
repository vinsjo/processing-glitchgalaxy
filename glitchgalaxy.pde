int fps = 5;
float rotationSpeed = 0.05;

PVector axisSpeed = new PVector(0.5, 0.25, 1);

color bg = color(0, 0, 0);
color accent = color(250, 250, 250);
boolean setColors = false;

int sphereCount = 5000;
int sphereDetail = 5;
float sphereMax = 3;
float sphereMin = 0.5;
float sphereDistDeviation = 2;

int noiseCount = 50000;
float noiseMin = 0.1;
float noiseMax = 1.5;

float glitchChance = 0.1;
float glitchInvertChance = 0.02;
int glitchIterationsMin = 1;
int glitchIterationsMax = 50;
float tileDividerMin = 1.2;
float tileDividerMax = 10;

boolean saveFrames = true;
String outputPath = "./output/";
String outputExt = "jpg";
int maxFrames = 10 * 60 * 60;
int startFrame = 0;

PVector pxCenter;
PVector vwCenter;
PVector[] points;
float[] sphereSizes;
color[] sphereColors;


void setup() {
  size(1280, 720, P3D);
  pixelDensity(displayDensity());
  frameRate(fps);
  background(bg);
  noStroke();
  noSmooth();
  sphereDetail(sphereDetail);
  points = new PVector[sphereCount];
  sphereSizes = new float[sphereCount];
  sphereColors = new color[sphereCount];
  pxCenter = new PVector(pixelWidth / 2, pixelHeight / 2);
  vwCenter = new PVector(width / 2, height / 2);
  float maxDist = dist(0, 0, width / 2, height / 2);
  PVector center = new PVector(0, 0, 0);
  PVector centerOffsetXYZ = new PVector(maxDist, maxDist, maxDist * 0.25);
  for (int i = 0; i < points.length; i++) {
    points[i] = gaussPoint3D(center, centerOffsetXYZ, sphereDistDeviation);
    float dist = PVector.dist(center, points[i]);

    sphereSizes[i] = constrain(
      gaussMap(1, 0.4, 2) * map(dist, 0, maxDist, sphereMax, sphereMin),
      sphereMin,
      sphereMax
      );

    float a = int(constrain(
      map(random(1) * map(dist, 0, maxDist, 100, 0), 1, 100, 0, 100),
      0,
      100
      ));

    if (setColors) {
      colorMode(HSB, 360, 100, 100, 100);
      float hue = constrain(map(dist, 0, maxDist, 30, -45), -360, 360);
      if (hue < 0) {
        hue += 360;
      }
      float saturation = constrain(gaussMap(100, 10, 3), 80, 100);
      float brightness = constrain(map(abs(points[i].z), 0, maxDist, 100, 0), 0, 100);
      sphereColors[i] = color(hue, saturation, brightness, a);
      colorMode(RGB, 255, 255, 255, 100);
    } else {
      sphereColors[i] = color(red(accent), green(accent), blue(accent), a);
    }
  }
}

void draw() {
  if (frameCount > maxFrames) {
    noLoop();
  }
  push();
  translate(vwCenter.x + gaussMap(0, 0.5, 2), vwCenter.y + gaussMap(0, 0.5, 2));
  float rot = radians(frameCount * rotationSpeed);
  rotateX(axisSpeed.x * rot);
  rotateY(axisSpeed.y * rot);
  rotateZ(axisSpeed.z * rot);
  fill(accent);
  for (int i = 0; i < points.length; i++) {
    push();
    fill(sphereColors[i]);
    translate(points[i].x, points[i].y, points[i].z);
    sphere(sphereSizes[i]);
    pop();
  }
  pop();

  addNoise(noiseCount, noiseMin, noiseMax, color(0), 1);
  if (frameCount >= startFrame) {
    if (random(1) < glitchChance) {
      moveRandomTile(
        int(random(glitchIterationsMin, glitchIterationsMax)),
        0.4,
        glitchInvertChance,
        bg
        );
    }
    if (saveFrames) {
      saveFrame(outputPath+"#####."+outputExt);
    }
  }
}


float gaussMap(float base, float offset, float deviation) {
  float min = base - offset;
  float max = base + offset;
  return map(randomGaussian(), -deviation, deviation, min, max);
}

PVector gaussPoint3D(PVector center, PVector offset, float deviation) {
  return new PVector(
    gaussMap(center.x, offset.x, deviation),
    gaussMap(center.y, offset.y, deviation),
    gaussMap(center.z, offset.z, deviation)
    );
}

PVector constrain3D(PVector src, PVector bounds) {
  return new PVector(
    constrain(src.x, -bounds.x, bounds.x),
    constrain(src.y, -bounds.y, bounds.y),
    constrain(src.z, -bounds.z, bounds.z)
    );
}

color invertRGB(color src) {
  return color(255 - red(src), 255 - green(src), 255 - blue(src));
}

void moveRandomTile(int iterations, float gaussDeviation, float invertChance, color bgColor) {
  for (int i = 0; i < iterations; i++) {
    loadPixels();
    int tileMax = min(width, height);
    int tileW = floor(tileMax / random(tileDividerMin, tileDividerMax));
    int tileH = floor(tileMax / random(tileDividerMin, tileDividerMax));

    PVector srcStart = new PVector(
      constrain(floor(gaussMap(pxCenter.x, pxCenter.x, gaussDeviation)), 0, pixelWidth - tileW),
      constrain(floor(gaussMap(pxCenter.y, pxCenter.y, gaussDeviation)), 0, pixelHeight - tileH)
      );
    PVector dstStart = new PVector(
      constrain(floor(gaussMap(pxCenter.x, pxCenter.x, gaussDeviation)), 0, pixelWidth - tileW),
      constrain(floor(gaussMap(pxCenter.y, pxCenter.y, gaussDeviation)), 0, pixelHeight - tileH)
      );

    PVector srcEnd = new PVector(srcStart.x + tileW, srcStart.y + tileH);
    PVector dstEnd = new PVector(dstStart.x + tileW, dstStart.y + tileH);

    PVector src = new PVector(srcStart.x, srcStart.y);
    PVector dst = new PVector(dstStart.x, dstStart.y);

    boolean copySrc = random(1) < 0.5;
    boolean copyDst = random(1) < 0.5;
    boolean overWriteSrc = random(1) < 0.5;
    boolean invertSrc = random(1) < invertChance;
    boolean invertDst = random(1) < invertChance;


    while (src.x * src.y < srcEnd.x * srcEnd.y && dst.x * dst.y < dstEnd.x * dstEnd.y) {
      if (src.x > srcEnd.x || src.x >= pixelWidth || dst.x >= pixelWidth) {
        src.x = srcStart.x;
        dst.x = dstStart.x;
        src.y++;
        dst.y++;
      }
      int srcIndex = floor(src.y * pixelWidth + src.x);
      int dstIndex = floor(dst.y * pixelWidth + dst.x);
      if (
        srcIndex >= pixels.length ||
        dstIndex >= pixels.length ||
        srcIndex < 0 ||
        dstIndex < 0
        ) {
        break;
      }


      color pxSrc = bgColor;
      color pxDst = bgColor;
      if (copySrc) {
        pxSrc = pixels[srcIndex];
        if (invertSrc) {
          pxSrc = invertRGB(pxSrc);
        }
      }
      if (copyDst) {
        pxDst = pixels[dstIndex];
        if (invertDst) {
          pxDst = invertRGB(pxSrc);
        }
      }
      if (overWriteSrc) {
        pixels[srcIndex] = pxDst;
      }
      pixels[dstIndex] = pxSrc;
      src.x++;
      dst.x++;
    }
    updatePixels();
  }
}

void addNoise(int pointCount, float strokeMin, float strokeMax, color noiseColor, float gaussDeviation) {
  PVector center = new PVector(width / 2, height / 2);
  for (int i = 0; i < pointCount; i++) {
    strokeWeight(random(strokeMin, strokeMax));
    stroke(color(red(noiseColor), green(noiseColor), blue(noiseColor), random(5, 100)));
    point(gaussMap(center.x, center.x, gaussDeviation), gaussMap(center.y, center.y, gaussDeviation));
  }
  stroke(0);
  noStroke();
}
