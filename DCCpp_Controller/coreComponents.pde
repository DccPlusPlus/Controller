//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Core Components
//
//  PowerButton  -  send power on/off command to the DCC++ Base Station
//
//  CurrentMeter -  monitors main track current draw from the DCC++ Base Station
//               -  displays scrolling bar chart of current measured
//
//  HelpButton   -  toggles Help Window
//
//  QuitButton   -  quits DCC++ Controller
//               -  connection to DCC++ Base Station terminated
//               -  NOTE: track power remains on and trains will continue to operate
//                  since DCC+ Base Station operates independently!
//
//  AccessoryButton   -  sends a DCC ACCESSORY COMMAND to the DCC++ Base Station
//                       to either activate or de-activate an accessory depending on
//                       whether the button is labeled "ON" or "OFF"
//                    -  two pre-specified input boxes are used: one for the user
//                       to input the desired accessory address, and one for
//                       accessory number (sub-address)
//                    -  the default configuration of DCC++ Controller defines an
//                       Accessory Window that includes these two input boxes as well
//                       as ON and OFF buttons.
//
//  CleaningCarButton -  sends a DCC THROTTLE COMMAND to the DCC++ Base Station that operates
//                       a mobile decoder with a pre-specified cab number
//                    -  this decoder drives a motor that spins a cleaning pad in a
//                       track-cleaning car
//                    -  clicking the button toggles the throttle between either 0 or 126 (max speed)
//                    -  the default configuration of DCC++ Controller defines an
//                       Extras Window that includes this button
//
//  LEDColorButton    -  provide for interactive control of an LED-RGB Light Strip

//////////////////////////////////////////////////////////////////////////
//  DCC Component: PowerButton
//////////////////////////////////////////////////////////////////////////

class PowerButton extends RectButton{

  PowerButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText);
  }
  
  PowerButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(0), fontSize, bText, ButtonType.NORMAL);
  } // PowerButton
  
//////////////////////////////////////////////////////////////////////////

  void turnOn(){
    aPort.write("<1>");
  }
  
//////////////////////////////////////////////////////////////////////////

  void shiftPressed(){
    aPort.write("<Z 1 0>");
    exit();
  }
  
//////////////////////////////////////////////////////////////////////////

  void turnOff(){
    aPort.write("<0>");
  }
    
} // PowerButton Class

//////////////////////////////////////////////////////////////////////////
//  DCC Component: CurrentMeter
//////////////////////////////////////////////////////////////////////////

class CurrentMeter extends DccComponent{
  int nSamples, kHeight;
  int maxCurrent;
  int[] samples;
  int sampleIndex;
  int nGridLines;
  boolean isOn;
  
  CurrentMeter(int xPos, int yPos, int nSamples, int kHeight, int maxCurrent, int nGridLines){
    this.xPos=xPos;
    this.yPos=yPos;
    this.nSamples=nSamples;
    this.kHeight=kHeight;
    this.maxCurrent=maxCurrent;
    this.nGridLines=nGridLines;
    this.isOn=true;
    samples=new int[nSamples];
    sampleIndex=nSamples-1;
    dccComponents.add(this);
  } // CurrentMeter

//////////////////////////////////////////////////////////////////////////
  
  void display(){
    int i;
    rectMode(CORNER);
    noFill();
    strokeWeight(1);
    textFont(buttonFont,8);
    textAlign(LEFT,CENTER);
    stroke(200);
    rect(xPos,yPos,nSamples+1,kHeight+2);
    if(isOn)
      stroke(50,200,100);
    else
      stroke(200,100,100);
    for(i=0;i<nSamples;i++){
      line(xPos+1+i,yPos+kHeight+1,xPos+1+i,yPos+kHeight+1-samples[(sampleIndex+i)%nSamples]*kHeight/maxCurrent);
    }
    stroke(200);
    for(i=1;i<nGridLines;i++){
      line(xPos+1,yPos+kHeight+1-kHeight*i/nGridLines,xPos+1+nSamples,yPos+kHeight+1-kHeight*i/nGridLines);
    }
    fill(255);
    for(i=0;i<=nGridLines;i++){
      text(nf(i*2000/nGridLines,0)+" mA",xPos+10+nSamples,yPos+kHeight+1-kHeight*i/nGridLines);
    }
  } // display
  
//////////////////////////////////////////////////////////////////////////

  void addSample(int s){

    samples[sampleIndex]=s;    
    sampleIndex=(sampleIndex+1)%nSamples;      
  }
  
} // CurrentMeter Class

//////////////////////////////////////////////////////////////////////////
//  DCC Component: AccessoryButton
//////////////////////////////////////////////////////////////////////////

class AccessoryButton extends EllipseButton{
  InputBox accAddInput, accSubAddInput;

  AccessoryButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox accAddInput, InputBox accSubAddInput){
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText, accAddInput, accSubAddInput);
  }
  
  AccessoryButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText, InputBox accAddInput, InputBox accSubAddInput){
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
    this.accAddInput=accAddInput;
    this.accSubAddInput=accSubAddInput;
  } // AccessoryButton

//////////////////////////////////////////////////////////////////////////

  void pressed(){
    super.pressed();
    int accAddress=accAddInput.getIntValue();
    int accSubAddress=accSubAddInput.getIntValue();
    if(accAddress>511)
       msgBoxMain.setMessage("Error - Accessory Address must be in range 0-511",color(255,30,30));
    else if(accSubAddress>3)
       msgBoxMain.setMessage("Error - Accessory Sub Address must be in range 0-3",color(255,30,30));
    else
       aPort.write("<a"+accAddress+" "+accSubAddress+" "+(bText.equals("ON")?1:0)+">");
  }
  
} // AccessoryButton Class

//////////////////////////////////////////////////////////////////////////
//  DCC Component: Quit Button
//////////////////////////////////////////////////////////////////////////

class QuitButton extends RectButton{

  QuitButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText);
  }
  
  QuitButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.NORMAL);
  } // PowerButton
  
//////////////////////////////////////////////////////////////////////////

  void turnOn(){
    super.turnOn();
    exit();
  }
      
} // QuitButton Class

//////////////////////////////////////////////////////////////////////////
//  DCC Component: Help Button
//////////////////////////////////////////////////////////////////////////

class HelpButton extends EllipseButton{

  HelpButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText);
  }
  
  HelpButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
  } // PowerButton
  
//////////////////////////////////////////////////////////////////////////

  void pressed(){
    super.pressed();
    helpWindow.toggle();
  }
      
} // HelpButton Class

//////////////////////////////////////////////////////////////////////////
//  DCC Component: CleaningCar Button
//////////////////////////////////////////////////////////////////////////

class CleaningCarButton extends RectButton{
  int cab;
  int reg;

  CleaningCarButton(int cab, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    this(null, cab, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText);
  }
  
  CleaningCarButton(Window window, int cab, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(0), fontSize, bText, ButtonType.NORMAL);
    reg=cabButtons.size()+1;
    this.cab=cab;
  } // PowerButton
  
//////////////////////////////////////////////////////////////////////////

  void turnOn(){
    super.turnOn();
    aPort.write("<t"+reg+" "+cab+" 126 1>");

  }

//////////////////////////////////////////////////////////////////////////

  void turnOff(){
    super.turnOff();
    aPort.write("<t"+reg+" "+cab+" 0 1>");
  }

//////////////////////////////////////////////////////////////////////////

  void shiftPressed(){
    autoPilot.clean();
  }
        
} // CleaningCarButton Class
  
//////////////////////////////////////////////////////////////////////////
//  DCC Component: LED Color Button
//////////////////////////////////////////////////////////////////////////

class LEDColorButton extends DccComponent{
  
  int bWidth, bHeight;
  float hue;
  float sat;
  float val;
  
  LEDColorButton(Window window, int xPos, int yPos, int bWidth, int bHeight, float hue, float sat, float val){
    this.xPos=xPos;
    this.yPos=yPos;
    this.bWidth=bWidth;
    this.bHeight=bHeight;
    this.hue=hue;
    this.sat=sat;
    this.val=val;
    this.window=window;
    window.windowComponents.add(this);
  }

//////////////////////////////////////////////////////////////////////////
  
  void display(){
    rectMode(CENTER);
    colorMode(HSB,1.0,1.0,1.0);
    fill(hue,sat,val);
    rect(xPos+xWindow(),yPos+yWindow(),bWidth,bHeight);
    colorMode(RGB,255);
  }

//////////////////////////////////////////////////////////////////////////
  
  void update(int s){
    color c;
    colorMode(HSB,1.0,1.0,1.0);
    c=color(hue,sat,val);
    colorMode(RGB,255);
    aPort.write("<G RGB "+int(red(c))+" "+int(green(c))+" "+int(blue(c))+" "+s+">");
    ledHueMsg.setMessage("Hue:   "+int(hue*360),color(200,200,200));
    ledSatMsg.setMessage("Sat:   "+int(sat*100),color(200,200,200));
    ledValMsg.setMessage("Val:   "+int(val*100),color(200,200,200));
    ledRedMsg.setMessage("Red:   "+int(red(c)),color(200,200,200));
    ledGreenMsg.setMessage("Green: "+int(green(c)),color(200,200,200));
    ledBlueMsg.setMessage("Blue:  "+int(blue(c)),color(200,200,200));
  }
  
} // LEDColorButton Class

//////////////////////////////////////////////////////////////////////////
//  DCC Component: LED Value Selector
//////////////////////////////////////////////////////////////////////////

class LEDValSelector extends DccComponent{
  
  int bWidth, bHeight;
  LEDColorButton cButton;
  PImage valBox;
    
  LEDValSelector(Window window, int xPos, int yPos, int bWidth, int bHeight, LEDColorButton cButton){
    this.xPos=xPos;
    this.yPos=yPos;
    this.bWidth=bWidth;
    this.bHeight=bHeight;
    this.cButton=cButton;
    valBox = createImage(bWidth+1,bHeight+1,RGB);
    this.window=window;
    window.windowComponents.add(this);
    
    colorMode(HSB,1.0,1.0,1.0);
    valBox.loadPixels();
    
    for(int y=0;y<valBox.height;y++){
      for(int x=0;x<valBox.width;x++){
        valBox.pixels[x+y*valBox.width]=color(0,0,float(x)/float(bWidth));    // since x will be maximum at width of box, normalize by bWidth which is one less than box width to ensure max brightness is 1.0
      }
    }
    
    valBox.updatePixels();
    colorMode(RGB,255);
        
  }
  
//////////////////////////////////////////////////////////////////////////

  void display(){
    
    imageMode(CORNER);
    colorMode(HSB,1.0,1.0,1.0);
    tint(cButton.hue,cButton.sat,1.0);
    image(valBox,xPos+xWindow(),yPos+yWindow());
    noTint();    
    fill(0.0,0.0,1.0);
    noStroke();
    pushMatrix();
    translate(xPos+xWindow()+cButton.val*float(bWidth),yPos+yWindow()-2);
    triangle(0,0,-5,-10,5,-10);
    translate(0,bHeight+4);
    triangle(0,0,-5,10,5,10);
    rectMode(CORNER);
    rect(-5,10,10,10);
    fill(0,0,0);
    triangle(0,15,-5,20,5,20);
    popMatrix();
    colorMode(RGB,255);
  }

//////////////////////////////////////////////////////////////////////////

  void check(){
    
    if(selectedComponent==null && mouseX>=xPos+xWindow()+cButton.val*float(bWidth)-5 && mouseX<=xPos+xWindow()+cButton.val*float(bWidth)+5 && mouseY>=yPos+yWindow()+bHeight+2 && mouseY<=yPos+yWindow()+bHeight+22){
      cursorType=HAND;
      selectedComponent=this;
    }
  }

//////////////////////////////////////////////////////////////////////////

  void drag(){
    cButton.val=constrain(float(mouseX-xPos-xWindow())/bWidth,0.0,1.0);
    cButton.update(0);
  }

//////////////////////////////////////////////////////////////////////////

  void released(){
    cButton.update(1);
  }
  
} // LEDValSelector Class

//////////////////////////////////////////////////////////////////////////
//  DCC Component: LED Color Selector
//////////////////////////////////////////////////////////////////////////

class LEDColorSelector extends DccComponent{
    
  PImage colorWheel;
  int radius;
  LEDColorButton cButton;
    
  LEDColorSelector(Window window, int xPos, int yPos, int radius, LEDColorButton cButton){
    float d, h;
    
    this.xPos=xPos;
    this.yPos=yPos;
    this.radius=radius;
    this.cButton=cButton;
    colorWheel=createImage(radius*2+1,radius*2+1,RGB);
    this.window=window;
    window.windowComponents.add(this);
    
    colorWheel.loadPixels();        
    colorMode(HSB,1.0,1.0,1.0);
       
    for(int i=0, y=radius;y>=-radius;y--){
      for(int x=-radius;x<=radius;x++){
        d=sqrt(x*x+y*y);
        if(d<0.5){
          colorWheel.pixels[i]=color(0.0,0.0,1.0);      // center of wheel always has zero saturation (hue does not matter)
        } else
        if(d>radius){
          colorWheel.pixels[i]=color(0.0,0.0,0.0);        // outside of wheel is always fully black (hue and saturation does not matter)
        } else {
          h=acos(float(x)/d);                            // find angle in radians
          if(y<0)                                        // adjust angle to reflect lower half of wheel
            h=TWO_PI-h;
          colorWheel.pixels[i]=color(h/TWO_PI,d/float(radius),1.0);    // hue is based on angle normalized to 1.0, saturation is based on distance to center normalized to 1.0, brightness is always 1.0
        }
        i++;
      } // x-loop
    }  // y-loop
             
    colorMode(RGB,255);
    colorWheel.updatePixels();
  }

//////////////////////////////////////////////////////////////////////////

  void display(){
    imageMode(CENTER);
    colorMode(HSB,1.0,1.0,1.0);
    image(colorWheel,xPos+xWindow(),yPos+yWindow());
    colorMode(RGB,255);
  
  }

//////////////////////////////////////////////////////////////////////////

  void check(){
        
    if(selectedComponent==null && ((pow(mouseX-xPos-xWindow(),2)+pow(mouseY-yPos-yWindow(),2))<=pow(radius,2))){
      cursorType=CROSS;
      selectedComponent=this;
    }
    
  } // check

//////////////////////////////////////////////////////////////////////////

  void pressed(){
    drag();
  }

//////////////////////////////////////////////////////////////////////////

  void drag(){
    float d,h;
    color selectedColor;
    
    d=sqrt(pow(mouseX-xPos-xWindow(),2)+pow(mouseY-yPos-yWindow(),2));
    if(d<0.5){
      h=0.0;
    } else {
      h=acos(float(mouseX-xPos-xWindow())/d);
      if(mouseY>(yPos+yWindow()))
        h=TWO_PI-h;
      cButton.hue=h/TWO_PI;
      cButton.sat=constrain(d/float(radius),0.0,1.0);
    }
     
    cButton.update(0);
    
  }

//////////////////////////////////////////////////////////////////////////

  void released(){
    cButton.update(1);
  }

} // LEDColorSelector Class
  
//////////////////////////////////////////////////////////////////////////
    