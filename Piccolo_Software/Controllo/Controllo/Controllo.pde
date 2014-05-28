/*
Controllo 
by: Diatom Studio , 2013

This program controls and sends drawing commands to a Piccolo teathered by a usb cable. 
All coodinates are sent in pixels/mm and are scaled for drawing to the screen. 
Coordinates are centred around XYZ at 0,0,0.
*/

/*
Notes:
- Should we separate plotsiWriter to it's own library?
- Could Controllo be a example in this library?
- Can we make seperate sketches / apps for generative drawings etc so that we can keep controllo clean and simple?
- If so how would a exhibition setup work? webpage to launch diff apps.
*/

//Libraries
import controlP5.*;
import processing.serial.*;
import java.awt.FileDialog;
import geomerative.*;
import java.util.*;
import javax.swing.JOptionPane;


boolean view3D = false; // display view in 3D


//Piccolo bed size in mm
float bedWidth = 50.0; 
float bedHeight = 50.0; 
float bedDepth = 50.0; 




float bedRenderWidth = 300;

//current position of drawing command to send
float xPos = 0;        
float yPos = 0;      
float zPos = 0;  


boolean fitSVGtoBed = true;


//TODO: this should be removed or moved to make code more straight forward.
//sensor sets
public float lightLevel = 0.5;

PShape loadedSVG; //svg loaded for sending to piccolo.
/*
Currently loaded SVG is shown on screen until user presses start. 
At this point the SVG is loaded into the output canvas and sent to Piccolo. 
It might be a better idea to always load drawing shapes directly into the output 
canvas so that they always reflect what Piccolo is drawing. 
*/


List path = new ArrayList();

PlotsiWriter writer = new PlotsiWriter(bedWidth,bedHeight,bedDepth);
ControlP5 controlP5;
CheckBox drawPlotsiOutput;
Knob pressureKnob;

PGraphics plotsiOutputCanvas;  //all lines drawn to this canvas will be sent to Piccolo







void setup() {
  size(500, 340,P3D);
  plotsiOutputCanvas = createGraphics((int)bedWidth, (int)bedHeight);
  plotsiOutputCanvas.beginDraw();
  plotsiOutputCanvas.smooth();
  plotsiOutputCanvas.endDraw();

  //canvas defaults
  writer.setStepRes(1f);
  writer.bezierDetail(20); 

  //setup GUI
  controlP5 = new ControlP5(this);
  drawInterface();

  String s = (String) JOptionPane.showInputDialog(
      null,
      "Select Piccolo's COM Port",
      "Select Piccolo",
      JOptionPane.PLAIN_MESSAGE,
      null,
      Serial.list(),
      Serial.list()[Serial.list().length-1]
  );

  println(s);

  // List all the available serial ports
  //TODO: select serial port at this point. 
try{
  writer.serial = new Serial(this, s, 115200);
  writer.serial.bufferUntil('\n');
  serialConnected = true;
}catch(Exception e){
  serialConnected = false;

}
  

  // Initialise Geomerative for working with type.
  RG.init(this);
  delay(200);
  home();
}











void draw() {

  background(255, 255, 255);
  ortho(0, width, 0, height); // same as ortho()
  pushMatrix();
  translate((bedRenderWidth/2) + 150, (bedRenderWidth/2)+20,0);
  

  if(view3D){
    rotateX(PI/4.0);
    rotateZ(PI/4.0);
    translate(0,0,(bedRenderWidth/2));
   }

  stroke(0);
  noFill();

  pushMatrix();
  translate(0,0,-(bedRenderWidth/2));
  rect(-(bedRenderWidth/2),-(bedRenderWidth/2),bedRenderWidth,bedRenderWidth);
  popMatrix();

  writer.draw(g,bedRenderWidth);
  popMatrix();
  writer.serialLoop();
}










void keyPressed(){
  if(key == '3')
    view3D = true;

    if(key == '2')
    view3D = false;
}



public void penUp(int val) {
  writer.clear(); 
  writer.vertex(0 , 0, penLiftHeight);
  writer.vertex(0, 0, penLiftHeight);

  writer.establishContact();
}

public void penDown(int val) {
  writer.clear(); 
  writer.vertex(0, 0, 0);
  writer.vertex(0, 0, 0);

  writer.establishContact();
}







public void load_SVG(int val) {

  FileDialog fd = new FileDialog(frame, "open", 
  FileDialog.LOAD);
  String currentDir = new File(".").getAbsolutePath();


  fd.setLocation(50, 50);
  fd.pack();
  fd.show();

  if (fd.getName() != null) {

    String filename = fd.getFile();
    clearCanvas();
    PShape svg = loadShape(fd.getDirectory() + filename);
    svg.disableStyle();
    writer.beginDraw();
    writer.clear();
    writer.pushMatrix();

    if(fitSVGtoBed)
    writer.scale(bedWidth / max(svg.width,svg.height) );
    else
    writer.scale(0.16666666666667);

    writer.translate(-(bedWidth/2.0),-(bedHeight/2.0),0.0);
    writer.shape(svg,0,0);
    writer.popMatrix();
    writer.endDraw();

    //loadedSVG.scale(0.6); 
    //
  } 
  else {
    // println("not an stl file");
  }
}




void clearCanvas() {
  plotsiOutputCanvas = createGraphics((int)bedWidth, (int)bedHeight);
  plotsiOutputCanvas.beginDraw();
  plotsiOutputCanvas.smooth();
  //plotsiOutputCanvas.background(255);
  plotsiOutputCanvas.endDraw();
  loadedSVG = null;
}



void up_() {
  penDownHeight+=5;
  penLiftHeight = penDownHeight+40;
  writer.clear();
  writer.stepTo(0, 0, penDownHeight);
  writer.establishContact();
  clearCanvas();
}

void down_() {
  penDownHeight-=5;
  println(penDownHeight);
  penLiftHeight = penDownHeight+40;
  writer.clear();
  writer.stepTo(0, 0, penDownHeight);
  writer.establishContact();
  clearCanvas();
}

void home() {
  writer.clear();
  writer.stepTo(0, 0, penLiftHeight);
  writer.establishContact();
 // clearCanvas();
}


void stop(){
 writer.clear();
}


public void Up(int val) {
  println("Up");
  writer.clear();
  writer.establishContact();
  if (zPos<90)
  {
    zPos+=10;
    writer.stepTo(xPos, yPos, zPos);
  }
  print("myZ:");
  println(xPos);
  println(yPos);
  println(zPos);
}

public void Down(int val) {
  writer.clear();
  writer.establishContact();
  if (zPos>10)
  {
    zPos-=10;
    writer.stepTo(xPos, yPos, zPos);
  }
  print("myZ:");
  println(xPos);
  println(yPos);
  println(zPos);
}



// =========================================================== //

public void TicTacToe() {
  writer.clear();
  clearCanvas();
  drawGrid(writer);
}

public void generate_tree() {
  writer.clear();
  clearCanvas();
  generatePlant( lightLevel, writer);
}

public void generate_mustache() {
  writer.clear();
  clearCanvas();
  drawMustache(writer);
}

public void logo(int val) {
  writer.clear();
  clearCanvas();
  loadedSVG = loadShape("logo.svg");
}

public void circles() {
  writer.clear();
  clearCanvas();
  drawCircles(writer);
}

public void boxes() {
  writer.clear();
  clearCanvas();
  drawBoxes(writer);
}

public void diagonals() {
  writer.clear();
  clearCanvas();
  drawDiagonals(writer);
}

public void word() {
  writer.clear();
  clearCanvas();
  drawWord(writer);
}

public void bezier(){
  writer.clear();
  clearCanvas();
  drawBezier(writer);

}







