// import libraries
import processing.opengl.*; // opengl
import SimpleOpenNI.*; // kinect
import blobDetection.*; // blobs

// this is a regular java import so we can use and extend the polygon class (see PolygonBlob)
import java.awt.Polygon;

// declare SimpleOpenNI object
SimpleOpenNI context;
// declare BlobDetection object
BlobDetection theBlobDetection;
// declare custom PolygonBlob object (see class for more info)
PolygonBlob poly = new PolygonBlob();

// PImage to hold incoming imagery and smaller one for blob detection
PImage cam, blobs;
// the kinect's dimensions to be used later on for calculations
int kinectWidth = 640;
int kinectHeight = 480;
// to center and rescale from 640x480 to higher custom resolutions
float reScale;

//color stuff
color backgroundColor = color(0,0,0);
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

void setup() {
  // it's possible to customize this, for example 1920x1080
  size(1280, 720, P3D);




  //fullScreen(P3D);
  // initialize SimpleOpenNI object
  context = new SimpleOpenNI(this);
  if (!context.enableDepth() || !context.enableUser()) { 
    // if context.enableScene() returns false
    // then the Kinect is not working correctly
    // make sure the green light is blinking
    println("Kinect not connected!"); 
    exit();
  } else {
    // mirror the image to be more intuitive
    context.setMirror(true);
    // calculate the reScale value
    // currently it's rescaled to fill the complete width (cuts of top-bottom)
    // it's also possible to fill the complete height (leaves empty sides)
    reScale = (float) width / kinectWidth;
    // create a smaller blob image for speed and efficiency
    blobs = createImage(kinectWidth/3, kinectHeight/3, RGB);
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
  // put the image into a PImage
  cam = context.userImage();

  //turn user image to black/white
  for (int i=0; i<cam.pixels.length; i++) {
    if (saturation(cam.pixels[i])<1) {
      cam.pixels[i] = color(0, 0, 0);
    } else {
      cam.pixels[i] = color(255, 255, 255);
    }
  }

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
    flow[i].col = particleColors[int(random(0,particleColors.length))];
  }
}
