//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Generic Ellipse and Rectangle Buttons
//
//  EllipseButton - base class for creating simple buttons
//                - operating buttons that extend EllipseButton should
//                  over-ride these methods with functionality specific
//                  to that button
//
//  RectButton    - variant of EllipseButton that define a rectanglular button
//
//////////////////////////////////////////////////////////////////////////

class EllipseButton extends DccComponent{
  int bWidth, bHeight;
  int baseHue;
  color textColor;
  int fontSize;
  String bText;
  ButtonType buttonType;
  int remoteCode;
  boolean isOn=false;
    
  EllipseButton(){
    this(width/2,height/2,80,50,100,color(0),16,"Button",ButtonType.NORMAL);
  }
 
  EllipseButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType){
    this(null, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, buttonType);
  }
  
  EllipseButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType){
    this.xPos=xPos;
    this.yPos=yPos;
    this.bWidth=bWidth;
    this.bHeight=bHeight;
    this.bText=bText;
    this.fontSize=fontSize;
    this.baseHue=baseHue;
    this.textColor=textColor;
    this.window=window;
    this.buttonType=buttonType;
    if(window==null)
      dccComponents.add(this);
    else
      window.windowComponents.add(this);
  } // EllipseButton

//////////////////////////////////////////////////////////////////////////
  
  void display(){
    colorMode(HSB,255);
    ellipseMode(CENTER);
    noStroke();
    fill(color(baseHue,255,isOn?255:125));
    ellipse(xPos+xWindow(),yPos+yWindow(),bWidth,bHeight);
    fill(textColor);
    textFont(buttonFont,fontSize);
    textAlign(CENTER,CENTER);
    text(bText,xPos+xWindow(),yPos+yWindow());
    if(buttonType==ButtonType.ONESHOT && isOn)
      turnOff();
    colorMode(RGB,255);
  } // display
  
//////////////////////////////////////////////////////////////////////////

  void check(){
    if(selectedComponent==null && (mouseX-xPos-xWindow())*(mouseX-xPos-xWindow())/(bWidth*bWidth/4.0)+(mouseY-yPos-yWindow())*(mouseY-yPos-yWindow())/(bHeight*bHeight/4.0)<=1){
      cursorType=HAND;
      selectedComponent=this;
    }
  } // check
  
//////////////////////////////////////////////////////////////////////////

  void turnOn(){
    isOn=true;
  }

//////////////////////////////////////////////////////////////////////////

  void turnOff(){
    isOn=false;
  }
  
//////////////////////////////////////////////////////////////////////////

  void pressed(){
    
    if(buttonType==ButtonType.REMOTE){
      aPort.write("<z"+remoteCode+" "+(isOn?"0>":"1>"));
      return;
    }
    
    if(isOn)
      turnOff();
    else
      turnOn();
  }
  
//////////////////////////////////////////////////////////////////////////

  void released(){
    if(buttonType==ButtonType.HOLD)
    turnOff();
  }
    
} // EllipseButton Class

//////////////////////////////////////////////////////////////////////////

class RectButton extends EllipseButton{
    
  RectButton(){
    super(width/2,height/2,80,50,100,color(0),16,"Button",ButtonType.NORMAL);
  }
 
  RectButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType){
    super(null, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, buttonType);
  }
  
  RectButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, ButtonType buttonType){
    super(window, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, buttonType);
  }

  RectButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, color textColor, int fontSize, String bText, int remoteCode){
    super(window, xPos, yPos, bWidth, bHeight, baseHue, textColor, fontSize, bText, ButtonType.REMOTE);
    this.remoteCode=remoteCode;
    remoteButtonsHM.put(remoteCode,this);    
  } // RectangleButton

//////////////////////////////////////////////////////////////////////////
  
  void display(){
    colorMode(HSB,255);
    rectMode(CENTER);
    noStroke();
    fill(color(baseHue,255,isOn?255:125));
    rect(xPos+xWindow(),yPos+yWindow(),bWidth,bHeight);
    fill(textColor);
    textFont(buttonFont,fontSize);
    textAlign(CENTER,CENTER);
    text(bText,xPos+xWindow(),yPos+yWindow());
    if(buttonType==ButtonType.ONESHOT && isOn)
      turnOff();
    colorMode(RGB,255);
  } // display
  
//////////////////////////////////////////////////////////////////////////

  void check(){
    if(selectedComponent==null && (mouseX>xPos+xWindow()-bWidth/2)&&(mouseX<xPos+xWindow()+bWidth/2)&&(mouseY>yPos+yWindow()-bHeight/2)&&(mouseY<yPos+yWindow()+bHeight/2)){
      cursorType=HAND;
      selectedComponent=this;
    }
  } // check
      
} // RectButton Class