// import libraries
import processing.opengl.*; // opengl
import SimpleOpenNI.*; // kinect
import blobDetection.*; // blobs
import java.awt.Polygon;

// declare SimpleOpenNI object
SimpleOpenNI context;
SimpleOpenNI context2;
// declare BlobDetection object
BlobDetection theBlobDetection;
// declare custom PolygonBlob object
PolygonBlob poly = new PolygonBlob();

PImage cam, blobs;
// the kinect's dimensions to be used later on for calculations
int kinectWidth = 640;
int kinectHeight = 480;
// to center and rescale from 640x480 to higher custom resolutions
float reScale;

boolean mirror;

//color stuff
color backgroundColor = color(0, 0, 0);
color[] particleColors = {
  color(255, 231, 27), 
  color(232, 126, 12), 
  color(255, 0, 0), 
  color(139, 12, 232)
};


// an array called flow of 2250 Particle objects (see Particle class)
Particle[] flow = new Particle[2250];
// global variables to influence the movement of all particles
float globalX, globalY;

void settings() {
  size(640*2, 480, P3D);
  //fullScreen(P3D);
}

void setup() {
  // it's possible to customize this, for example 1920x1080
  //size(1280, 720, P3D);

  //kinect 1
  context = new SimpleOpenNI(0, this);
  //kinect 2
  context2 = new SimpleOpenNI(1, this);

  if (!context.enableDepth() || !context.enableUser() || !context2.enableDepth() || !context2.enableUser() ) { 
    println("Kinect not connected!"); 
    exit();
  } else {
    //context.setMirror(mirror);
    //context2.setMirror(mirror);
    // calculate the reScale value
    // currently it's rescaled to fill the complete width (cuts of top-bottom)
    // it's also possible to fill the complete height (leaves empty sides)
    reScale = (float) width / (kinectWidth*2);
    // create a smaller blob image for speed and efficiency
    blobs = createImage( (kinectWidth/3) * 2, kinectHeight/3, RGB);
    // initialize blob detection object to the blob image dimensions
    theBlobDetection = new BlobDetection(blobs.width, blobs.height);
    theBlobDetection.setThreshold(0.9);
    setupFlowfield();
  }
}

void draw() {
  noCursor();
  // fading background
  noStroke();
  fill(backgroundColor, 20);
  rect(0, 0, width, height);
  // update the SimpleOpenNI object
  context.update();
  context2.update();

  // put the image into a PImage



  PImage cam1, cam2;

  cam1 = context.userImage();
  cam2 = context2.userImage();

  //turn user image to black/white

  //kinect 1
  for (int i=0; i<cam1.pixels.length; i++) {
    if (saturation(cam1.pixels[i])<1) {
      cam1.pixels[i] = color(0, 0, 0);
    } else {
      cam1.pixels[i] = color(255, 255, 255);
    }
  }

  //kinect 2
  for (int i=0; i<cam2.pixels.length; i++) {
    if (saturation(cam2.pixels[i])<1) {
      cam2.pixels[i] = color(0, 0, 0);
    } else {
      cam2.pixels[i] = color(255, 255, 255);
    }
  }

  //combine cam1 and cam2

  PGraphics combined = createGraphics(kinectWidth*2, kinectHeight);
  combined.beginDraw();

  //mirror it
  combined.pushMatrix();
  combined.translate(width/4, height/2);
  combined.imageMode(CENTER);
  combined.scale(-1, 1);
  combined.image(cam1, 0, 0);
  combined.popMatrix();

  combined.pushMatrix();
  combined.translate(width/4 + width/2, height/2);
  combined.scale(-1, 1);
  imageMode(CENTER);
  combined.image(cam2, 0, 0);
  combined.popMatrix();

  combined.endDraw();

  cam = combined.get();

  //endhack

  // copy the image into the smaller blob image
  blobs.copy(cam, 0, 0, cam.width, cam.height, 0, 0, blobs.width, blobs.height);
  // blur the blob image
  blobs.filter(BLUR);
  // detect the blobs
  theBlobDetection.computeBlobs(blobs.pixels);

  //image(cam, 0, 0, width, height);
  // clear the polygon (original functionality)
  poly.reset();
  // create the polygon from the blobs (custom functionality, see class)
  poly.createPolygon();
  drawFlowfield();
}

void setupFlowfield() {
  // set stroke weight (for particle display) to 2.5
  strokeWeight(1);
  // initialize all particles in the flow
  for (int i=0; i<flow.length; i++) {
    flow[i] = new Particle(i/10000.0);
  }
  // set all colors randomly now
  SetColor();
}

void drawFlowfield() {
  // center and reScale from Kinect to custom dimensions
  translate(0, (height-kinectHeight*reScale)/2);
  scale(reScale);
  // set global variables that influence the particle flow's movement
  globalX = noise(frameCount * 0.01) * width/2 + width/4;
  globalY = noise(frameCount * 0.005 + 5) * height;
  // update and display all particles in the flow
  for (Particle p : flow) {
    p.updateAndDisplay();
  }
  // set the colors randomly every 240th frame
}

// sets the colors every nth frame
void SetColor() {
  for (int i=0; i<flow.length; i++) {
    flow[i].col = particleColors[int(random(0, particleColors.length))];
  }
}
