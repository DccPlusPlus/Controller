//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Generic Input/Output Text Boxes
//
//  MessageBox  -  defines an output box for displaying text of specified
//              -  size, color, and background
//
//  InputBox    -  defines a box with text that can by input via the keyboard
//              -  box size and allowable characters can be constrained
//              -  text that is input is stored for later reference by other
//                 classes and methods
//              -  multiple boxes can be lniked so that they form a "tab" group
//              -  clicking on any object outside the input box ends the input mode
//              -  hitting "return" also ends the input mode
//
//////////////////////////////////////////////////////////////////////////

class MessageBox extends DccComponent{
  int kWidth, kHeight;
  color boxColor;
  color msgColor;
  int fontSize;
  String msgText;
  
  MessageBox(int xPos, int yPos, int kWidth, int kHeight, color boxColor, int fontSize){
    this(null, xPos, yPos, kWidth, kHeight, boxColor, fontSize);
  } // MessageBox

  MessageBox(int xPos, int yPos, int kWidth, int kHeight, color boxColor, int fontSize, String msgText, color msgColor){
    this(null, xPos, yPos, kWidth, kHeight, boxColor, fontSize);
    setMessage(msgText, msgColor);
  } // MessageBox

  MessageBox(Window window, int xPos, int yPos, int kWidth, int kHeight, color boxColor, int fontSize, String msgText, color msgColor){
    this(window, xPos, yPos, kWidth, kHeight, boxColor, fontSize);
    setMessage(msgText, msgColor);
  } // MessageBox

  MessageBox(Window window, int xPos, int yPos, int kWidth, int kHeight, color boxColor, int fontSize){
    this.xPos=xPos;
    this.yPos=yPos;
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.msgText="";
    this.msgColor=color(0,0,255);
    this.fontSize=fontSize;
    this.boxColor=boxColor;
    this.window=window;
    if(window==null)
      dccComponents.add(this);
    else
      window.windowComponents.add(this);
  } // MessageBox

//////////////////////////////////////////////////////////////////////////
  
  void display(){
    noStroke();
    rectMode(CENTER);
    fill(boxColor);
    rect(xPos+xWindow()-(kWidth<0?kWidth/2:0),yPos+yWindow(),abs(kWidth),kHeight);
    textFont(messageFont,fontSize);
    textAlign(kWidth<0?LEFT:CENTER,CENTER);
    fill(msgColor);
    text(msgText,xPos+xWindow(),yPos+yWindow());
  } // display
  
//////////////////////////////////////////////////////////////////////////

  void setMessage(String msgText, color msgColor){
    this.msgText=msgText;
    this.msgColor=msgColor;
  }

//////////////////////////////////////////////////////////////////////////

  void setMessage(String msgText){
    this.msgText=msgText;
  }
  
} // MessageBox Class

//////////////////////////////////////////////////////////////////////////
//  DCC Component: InputBox
//////////////////////////////////////////////////////////////////////////

class InputBox extends DccComponent{
  int kWidth, kHeight;
  int fontSize;
  color boxColor;
  color msgColor;
  String inputText="";
  int maxChars;
  Pattern regexp;
  InputType inputType;
  InputBox nextBox=null;
  ArrayList<InputBox> linkedBoxes = new ArrayList<InputBox>();

  InputBox(int xPos, int yPos, int fontSize, color boxColor, color msgColor, int maxChars, InputType inputType){
    this(null, xPos, yPos, fontSize, boxColor, msgColor, maxChars, inputType);
  }
    
  InputBox(Window window, int xPos, int yPos, int fontSize, color boxColor, color msgColor, int maxChars, InputType inputType){
    this.xPos=xPos;
    this.yPos=yPos;
    this.fontSize=fontSize;
    this.msgColor=msgColor;
    this.boxColor=boxColor;
    this.window=window;
    this.maxChars=maxChars;
    textFont(messageFont,fontSize);
    String s="0";
    for(int i=0;i<maxChars;i++,s+="0");
    this.kWidth=int(textWidth(s));
    this.kHeight=fontSize+4;
    this.inputType=inputType;
    linkedBoxes.add(this);
    regexp=regexp.compile(inputType.regexp);
    if(window==null)
      dccComponents.add(this);
    else
      window.windowComponents.add(this);
  } // InputBox

//////////////////////////////////////////////////////////////////////////
  
  void display(){
    String textCursor;
    noStroke();
    rectMode(CENTER);
    if(activeInputBox==this)
      fill(255);
    else
      fill(boxColor);
    rect(xPos+xWindow()+kWidth/2,yPos+yWindow(),kWidth,kHeight);
    textFont(messageFont,fontSize);
    textAlign(LEFT,CENTER);
    fill(msgColor);
    if(activeInputBox!=this && inputText.length()==0)
      textCursor="?";      
    else if(activeInputBox==this && (millis()/500)%2==1)
      textCursor="|";
    else
      textCursor="";
    text(inputText+textCursor,xPos+xWindow(),yPos+yWindow());
  } // display
  
//////////////////////////////////////////////////////////////////////////

  void check(){
    if(selectedComponent==null && (mouseX>xPos+xWindow())&&(mouseX<xPos+xWindow()+kWidth)&&(mouseY>yPos+yWindow()-kHeight/2)&&(mouseY<yPos+yWindow()+kHeight/2)){
      if(activeInputBox!=this)
        cursorType=TEXT;
      selectedComponent=this;
    }
  }
  
//////////////////////////////////////////////////////////////////////////

  void pressed(){
    activeInputBox=this;
  }
    
//////////////////////////////////////////////////////////////////////////

  void setNextBox(InputBox nextBox){
    this.nextBox=nextBox;
  }
    
//////////////////////////////////////////////////////////////////////////

  void linkBox(InputBox inputBox){
    linkedBoxes=inputBox.linkedBoxes;
    linkedBoxes.add(this);
  }
    
//////////////////////////////////////////////////////////////////////////

  int getIntValue(){
    if(inputText.length()==0)
      return 0;
    if(inputType==InputType.DEC)
      return int(inputText);
    if(inputType==InputType.BIN)
      return unbinary(inputText);
    if(inputType==InputType.HEX)
      return unhex(inputText);
    return 0;
  }
    
//////////////////////////////////////////////////////////////////////////

  void setIntValue(int v){
    if(inputType==InputType.DEC)
      inputText=str(v);
    else if(inputType==InputType.BIN)
      inputText=binary(v,8);
    else if(inputType==InputType.HEX)
      inputText=hex(v,2);
    else
      inputText="";
  }
    
//////////////////////////////////////////////////////////////////////////

  void resetValue(){
    inputText="";
  }
    
//////////////////////////////////////////////////////////////////////////

  void keyStroke(char k, int kC){
    if(kC!=CODED){
      if(regexp.matcher(str(k)).find() && inputText.length()<maxChars){
        inputText+=k;
      } else if(k==BACKSPACE && inputText.length()>0){
        inputText=inputText.substring(0,inputText.length()-1);
      } else if(k==ENTER || k==RETURN){
        activeInputBox=null;
        for( InputBox inputBox : linkedBoxes)
          inputBox.setIntValue(getIntValue());
      } else if(k==TAB){
        if(nextBox!=null)
          nextBox.pressed();
        else
          activeInputBox=null;
        for( InputBox inputBox : linkedBoxes)
          inputBox.setIntValue(getIntValue());
      }
    } // kc!=CODED
  } // keyStroke
  
} // InputBox Class

//////////////////////////////////////////////////////////////////////////