//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Configuration and Initialization
//
//  * Defines all global variables and objects
//
//  * Reads and loads previous status data from status files
//
//  * Implements track layout(s), throttles, track buttons, route buttons,
//    cab buttons, function buttons, windows, current meter,
//    and all other user-specified components
//
//////////////////////////////////////////////////////////////////////////

// DECLARE "GLOBAL" VARIABLES and OBJECTS

  PApplet Applet = this;                         // Refers to this program --- needed for Serial class

  int cursorType;
  String baseID;
  boolean keyHold=false;
  boolean saveXMLFlag=false;
  int lastTime;
  PFont throttleFont, messageFont, buttonFont;
  color backgroundColor;
  XML dccStatusXML, arduinoPortXML, sensorButtonsXML, autoPilotXML, cabDefaultsXML, serverListXML;
  
  DccComponent selectedComponent, previousComponent;
  ArrayList<DccComponent> dccComponents = new ArrayList<DccComponent>();
  ArrayList<CabButton> cabButtons = new ArrayList<CabButton>();
  ArrayList<CallBack> callBacks = new ArrayList<CallBack>();
  ArrayList<DccComponent> buttonQueue = new ArrayList<DccComponent>();
  ArrayList<DccComponent> buttonQueue2 = new ArrayList<DccComponent>();
  HashMap<Integer,EllipseButton> remoteButtonsHM = new HashMap<Integer,EllipseButton>();
  ArrayList<MessageBox> msgAutoCab = new ArrayList<MessageBox>();
  HashMap<Integer,TrackSensor> sensorsHM = new HashMap<Integer,TrackSensor>();    
  HashMap<String,CabButton> cabsHM = new HashMap<String,CabButton>();
  HashMap<Integer,TrackButton> trackButtonsHM = new HashMap<Integer,TrackButton>();  
  
  ArduinoPort       aPort;
  PowerButton       powerButton;
  AutoPilotButton   autoPilot;
  CleaningCarButton cleaningCab;
  Throttle          throttleA;
  Layout            layout,layout2,layoutBridge;
  MessageBox        msgBoxMain, msgBoxDiagIn, msgBoxDiagOut, msgBoxClock;
  CurrentMeter      currentMeter;
  Window            mainWindow, accWindow, progWindow, portWindow, extrasWindow, opWindow, diagWindow, autoWindow, sensorWindow, ledWindow;
  ImageWindow       imageWindow;
  JPGWindow         helpWindow;
  MessageBox        msgAutoState, msgAutoTimer;
  InputBox          activeInputBox;
  InputBox          accAddInput, accSubAddInput;
  InputBox          progCVInput, progHEXInput, progDECInput, progBINInput;
  InputBox          opCabInput, opCVInput, opHEXInput, opDECInput, opBINInput, opBitInput;
  InputBox          shortAddInput, longAddInput;
  MessageBox        activeAddBox;
  MessageBox        portBox, portNumBox;
  MessageBox        ledHueMsg, ledSatMsg, ledValMsg, ledRedMsg, ledGreenMsg, ledBlueMsg;
  PortScanButton    portScanButton;
  LEDColorButton    ledColorButton;
  
// DECLARE TRACK BUTTONS, ROUTE BUTTONS, and CAB BUTTONS WHICH WILL BE DEFINED BELOW AND USED "GLOBALLY"  

  TrackButton      tButton1,tButton2,tButton3,tButton4,tButton5;
  TrackButton      tButton6,tButton7,tButton8,tButton9,tButton10;
  TrackButton      tButton20,tButton30,tButton40,tButton50;
  
  RouteButton      rButton1,rButton2,rButton3,rButton4,rButton5,rButton6,rButton7;
  RouteButton      rButton10,rButton11,rButton12,rButton13,rButton14;
  RouteButton      rButtonR1,rButtonR2,rButton15,rButton16,rButton17,rButtonSpiral,rButtonReset,rButtonBridge;  

  CabButton        cab8601,cab54,cab1202,cab1506,cab622,cab2004,cab6021;
  
////////////////////////////////////////////////////////////////////////
//  Initialize --- configures everything!
////////////////////////////////////////////////////////////////////////

  void Initialize(){
    colorMode(RGB,255);
    throttleFont=loadFont("OCRAExtended-26.vlw");
    messageFont=loadFont("LucidaConsole-18.vlw");
    buttonFont=loadFont("LucidaConsole-18.vlw");
    rectMode(CENTER);
    textAlign(CENTER,CENTER);
    backgroundColor=color(50,50,60);

    aPort=new ArduinoPort();
    
// READ, OR CREATE IF NEEDED, XML DCC STATUS FILE
    
    dccStatusXML=loadXML(STATUS_FILE);
    if(dccStatusXML==null){
      dccStatusXML=new XML("dccStatus");
    }

    arduinoPortXML=dccStatusXML.getChild("arduinoPort");
    if(arduinoPortXML==null){
      arduinoPortXML=dccStatusXML.addChild("arduinoPort");
      arduinoPortXML.setContent("Emulator");
    }
    
    serverListXML=dccStatusXML.getChild("serverList");
    if(serverListXML==null){
      serverListXML=dccStatusXML.addChild("serverList");
      serverListXML.setContent("127.0.0.1");
    }
    
    sensorButtonsXML=dccStatusXML.getChild("sensorButtons");
    if(sensorButtonsXML==null){
      sensorButtonsXML=dccStatusXML.addChild("sensorButtons");
    }

    autoPilotXML=dccStatusXML.getChild("autoPilot");
    if(autoPilotXML==null){
      autoPilotXML=dccStatusXML.addChild("autoPilot");
    }
    
    cabDefaultsXML=dccStatusXML.getChild("cabDefaults");
    if(cabDefaultsXML==null){
      cabDefaultsXML=dccStatusXML.addChild("cabDefaults");
    }
    
    saveXMLFlag=true;
      
// CREATE THE ACCESSORY CONTROL WINDOW
    
    accWindow = new Window(500,200,300,160,color(200,200,200),color(200,50,50));
    new DragBar(accWindow,0,0,300,10,color(200,50,50));
    new CloseButton(accWindow,288,0,10,10,color(200,50,50),color(255,255,255));
    new MessageBox(accWindow,150,22,0,0,color(200,200,200),20,"Accessory Control",color(200,50,50));
    new MessageBox(accWindow,20,60,-1,0,color(200,200,200),16,"Acc Address (0-511):",color(200,50,50));
    accAddInput = new InputBox(accWindow,230,60,16,color(200,200,200),color(50,50,200),3,InputType.DEC);
    new MessageBox(accWindow,20,90,-1,0,color(200,200,200),16,"Sub Address   (0-3):",color(200,50,50));
    accSubAddInput = new InputBox(accWindow,230,90,16,color(200,200,200),color(50,50,200),1,InputType.DEC);
    new AccessoryButton(accWindow,90,130,55,25,100,18,"ON",accAddInput,accSubAddInput);
    new AccessoryButton(accWindow,210,130,55,25,0,18,"OFF",accAddInput,accSubAddInput);
    accAddInput.setNextBox(accSubAddInput);
    accSubAddInput.setNextBox(accAddInput);
    
// CREATE THE SERIAL PORT WINDOW
    
    portWindow = new Window(500,200,500,170,color(200,200,200),color(200,50,50));
    new DragBar(portWindow,0,0,500,10,color(200,50,50));
    new CloseButton(portWindow,488,0,10,10,color(200,50,50),color(255,255,255));
    new MessageBox(portWindow,250,22,0,0,color(200,200,200),20,"Select Arduino Port",color(200,50,50));
    portScanButton = new PortScanButton(portWindow,100,60,85,20,100,18,"SCAN");
    new PortScanButton(portWindow,400,60,85,20,0,18,"CONNECT");
    new PortScanButton(portWindow,120,140,15,20,120,18,"<");
    new PortScanButton(portWindow,380,140,15,20,120,18,">");
    portBox = new MessageBox(portWindow,250,100,380,25,color(250,250,250),20,"",color(50,150,50));
    portBox.setMessage("Please press SCAN",color(150,50,50));
    portNumBox = new MessageBox(portWindow,250,140,0,0,color(200,200,200),20,"",color(50,50,50));

// CREATE THE PROGRAMMING CVs ON THE PROGRAMMING TRACK WINDOW
    
    progWindow = new Window(500,100,500,400,color(200,180,200),color(50,50,200));
    new DragBar(progWindow,0,0,500,10,color(50,50,200));
    new CloseButton(progWindow,488,0,10,10,color(50,50,200),color(255,255,255));
    new RectButton(progWindow,250,30,210,30,40,color(0),18,"Programming Track",ButtonType.TI_COMMAND,101);        
    
    new MessageBox(progWindow,20,90,-1,0,color(200,180,200),16,"CV (1-1024):",color(50,50,200));
    new MessageBox(progWindow,20,130,-1,0,color(200,180,200),16,"Value (HEX):",color(50,50,200));
    new MessageBox(progWindow,20,160,-1,0,color(200,180,200),16,"Value (DEC):",color(50,50,200));
    new MessageBox(progWindow,20,190,-1,0,color(200,180,200),16,"Value (BIN):",color(50,50,200));
    progCVInput = new InputBox(progWindow,150,90,16,color(200,180,200),color(200,50,50),4,InputType.DEC);
    progHEXInput = new InputBox(progWindow,150,130,16,color(200,180,200),color(200,50,50),2,InputType.HEX);
    progDECInput = new InputBox(progWindow,150,160,16,color(200,180,200),color(200,50,50),3,InputType.DEC);
    progBINInput = new InputBox(progWindow,150,190,16,color(200,180,200),color(200,50,50),8,InputType.BIN);
    progCVInput.setNextBox(progHEXInput);
    progHEXInput.setNextBox(progDECInput);
    progDECInput.setNextBox(progBINInput);
    progDECInput.linkBox(progHEXInput);
    progBINInput.setNextBox(progHEXInput);
    progBINInput.linkBox(progHEXInput);        
    new ProgWriteReadButton(progWindow,300,90,65,25,100,14,"READ",progCVInput,progHEXInput);
    new ProgWriteReadButton(progWindow,390,90,65,25,0,14,"WRITE",progCVInput,progHEXInput);

    new MessageBox(progWindow,20,240,-1,0,color(200,180,200),16,"ENGINE ADDRESSES",color(50,50,200));
    new MessageBox(progWindow,20,280,-1,0,color(200,180,200),16,"Short  (1-127):",color(50,50,200));
    new MessageBox(progWindow,20,310,-1,0,color(200,180,200),16,"Long (0-10239):",color(50,50,200));
    new MessageBox(progWindow,20,340,-1,0,color(200,180,200),16,"Active        :",color(50,50,200));
    shortAddInput = new InputBox(progWindow,190,280,16,color(200,180,200),color(200,50,50),3,InputType.DEC);
    longAddInput = new InputBox(progWindow,190,310,16,color(200,180,200),color(200,50,50),5,InputType.DEC);
    activeAddBox = new MessageBox(progWindow,190,340,-1,0,color(200,180,200),16,"?",color(200,50,50));
    new ProgAddReadButton(progWindow,300,240,65,25,100,14,"READ",shortAddInput,longAddInput,activeAddBox);
    new ProgShortAddWriteButton(progWindow,300,280,65,25,0,14,"WRITE",shortAddInput);
    new ProgLongAddWriteButton(progWindow,300,310,65,25,0,14,"WRITE",longAddInput);
    new ProgLongShortButton(progWindow,300,340,65,25,0,14,"Long",activeAddBox);
    new ProgLongShortButton(progWindow,390,340,65,25,0,14,"Short",activeAddBox);

// CREATE THE PROGRAMMING CVs ON THE MAIN OPERATIONS TRACK WINDOW
    
    opWindow = new Window(500,100,500,300,color(220,200,200),color(50,50,200));
    new DragBar(opWindow,0,0,500,10,color(50,50,200));
    new CloseButton(opWindow,488,0,10,10,color(50,50,200),color(255,255,255));
    new MessageBox(opWindow,250,30,0,0,color(220,200,200),20,"Operations Programming",color(50,100,50));
    new MessageBox(opWindow,20,90,-1,0,color(220,200,200),16,"Cab Number :",color(50,50,200));
    new MessageBox(opWindow,20,120,-1,0,color(220,200,200),16,"CV (1-1024):",color(50,50,200));
    new MessageBox(opWindow,20,160,-1,0,color(220,200,200),16,"Value (HEX):",color(50,50,200));
    new MessageBox(opWindow,20,190,-1,0,color(220,200,200),16,"Value (DEC):",color(50,50,200));
    new MessageBox(opWindow,20,220,-1,0,color(220,200,200),16,"Value (BIN):",color(50,50,200));
    opCabInput = new InputBox(opWindow,150,90,16,color(220,200,200),color(200,50,50),5,InputType.DEC);
    opCVInput = new InputBox(opWindow,150,120,16,color(220,200,200),color(200,50,50),4,InputType.DEC);
    opHEXInput = new InputBox(opWindow,150,160,16,color(220,200,200),color(200,50,50),2,InputType.HEX);
    opDECInput = new InputBox(opWindow,150,190,16,color(220,200,200),color(200,50,50),3,InputType.DEC);
    opBINInput = new InputBox(opWindow,150,220,16,color(220,200,200),color(200,50,50),8,InputType.BIN);
    opCVInput.setNextBox(opHEXInput);
    opHEXInput.setNextBox(opDECInput);
    opDECInput.setNextBox(opBINInput);
    opDECInput.linkBox(opHEXInput);
    opBINInput.setNextBox(opHEXInput);
    opBINInput.linkBox(opHEXInput);        
    new OpWriteButton(opWindow,300,90,65,25,0,14,"WRITE",opCVInput,opHEXInput);
    new MessageBox(opWindow,20,260,-1,0,color(220,200,200),16,"  Bit (0-7):",color(50,50,200));
    opBitInput = new InputBox(opWindow,150,260,16,color(220,200,200),color(200,50,50),1,InputType.DEC);
    new OpWriteButton(opWindow,300,260,65,25,50,14,"SET",opCVInput,opBitInput);
    new OpWriteButton(opWindow,390,260,65,25,150,14,"CLEAR",opCVInput,opBitInput);

// CREATE THE DCC++ CONTROL <-> DCC++ BASE STATION COMMUNICATION DIAGNOSTICS WINDOW
    
    diagWindow = new Window(400,300,500,120,color(175),color(50,200,50));
    new DragBar(diagWindow,0,0,500,10,color(50,200,50));
    new CloseButton(diagWindow,488,0,10,10,color(50,200,50),color(255,255,255));
    new MessageBox(diagWindow,250,20,0,0,color(175),18,"Diagnostics Window",color(50,50,200));
    new MessageBox(diagWindow,10,60,-1,0,color(175),18,"Sent:",color(50,50,200));
    msgBoxDiagOut=new MessageBox(diagWindow,250,60,0,0,color(175),18,"---",color(50,50,200));
    new MessageBox(diagWindow,10,90,-1,0,color(175),18,"Proc:",color(50,50,200));
    msgBoxDiagIn=new MessageBox(diagWindow,250,90,0,0,color(175),18,"---",color(50,50,200));

// CREATE THE AUTOPILOT DIAGNOSTICS WINDOW 
    
    autoWindow = new Window(400,300,500,330,color(175),color(50,200,50));
    new DragBar(autoWindow,0,0,500,10,color(50,200,50));
    new CloseButton(autoWindow,488,0,10,10,color(50,200,50),color(255,255,255));
    new MessageBox(autoWindow,250,20,0,0,color(175),18,"AutoPilot Window",color(50,50,150));
    msgAutoState=new MessageBox(autoWindow,0,180,-1,0,color(175),18,"?",color(50,50,250));
    msgAutoTimer=new MessageBox(autoWindow,55,310,-1,0,color(175),18,"Timer =",color(50,50,250));
    
// CREATE THE SENSORS DIAGNOSTICS WINDOW 
    
    sensorWindow = new Window(400,300,500,350,color(175),color(50,200,50));
    new DragBar(sensorWindow,0,0,500,10,color(50,200,50));
    new CloseButton(sensorWindow,488,0,10,10,color(50,200,50),color(255,255,255));
    new MessageBox(sensorWindow,250,20,0,0,color(175),18,"Sensors Window",color(50,50,150));

// CREATE THE HELP WINDOW
      
  helpWindow=new JPGWindow("helpMenu.jpg",1000,650,100,50,color(0,100,0));    
        
// CREATE THE EXTRAS WINDOW:

    extrasWindow = new Window(500,200,500,250,color(255,255,175),color(100,100,200));
    new DragBar(extrasWindow,0,0,500,10,color(100,100,200));
    new CloseButton(extrasWindow,488,0,10,10,color(100,100,200),color(255,255,255));
    new MessageBox(extrasWindow,250,20,0,0,color(175),18,"Extra Functions",color(50,50,200));
//    new RectButton(extrasWindow,260,80,120,50,85,color(0),16,"Sound\nEffects",0);        

// CREATE THE LED LIGHT-STRIP WINDOW:

    ledWindow = new Window(500,200,550,425,color(0),color(0,0,200));
    new DragBar(ledWindow,0,0,550,10,color(0,0,200));
    new CloseButton(ledWindow,538,0,10,10,color(0,0,200),color(200,200,200));
    new MessageBox(ledWindow,275,20,0,0,color(175),18,"LED Light Strip",color(200,200,200));
    ledColorButton=new LEDColorButton(ledWindow,310,175,30,201,0.0,0.0,1.0);
    new LEDColorSelector(ledWindow,150,175,100,ledColorButton);
    new LEDValSelector(ledWindow,50,330,200,30,ledColorButton);
    ledHueMsg = new MessageBox(ledWindow,360,80,-1,0,color(175),18,"Hue:   -",color(200,200,200));
    ledSatMsg = new MessageBox(ledWindow,360,115,-1,0,color(175),18,"Sat:   -",color(200,200,200));
    ledValMsg = new MessageBox(ledWindow,360,150,-1,0,color(175),18,"Val:   -",color(200,200,200));
    ledRedMsg = new MessageBox(ledWindow,360,185,-1,0,color(175),18,"Red:   -",color(200,200,200));
    ledGreenMsg = new MessageBox(ledWindow,360,220,-1,0,color(175),18,"Green: -",color(200,200,200));
    ledBlueMsg = new MessageBox(ledWindow,360,255,-1,0,color(175),18,"Blue:  -",color(200,200,200));

// CREATE TOP-OF-SCREEN MESSAGE BAR AND HELP BUTTON

    msgBoxMain=new MessageBox(width/2,12,width,25,color(200),20,"Searching for Base Station: "+arduinoPortXML.getContent(),color(30,30,150));
    new HelpButton(width-50,12,22,22,150,20,"?");

// CREATE CLOCK

    msgBoxClock=new MessageBox(30,700,-100,30,backgroundColor,30,"00:00:00",color(255,255,255));
    
// CREATE POWER BUTTON, QUIT BUTTON, and CURRENT METER
    
    powerButton=new PowerButton(75,475,100,30,100,18,"POWER");
    new QuitButton(200,475,100,30,250,18,"QUIT");
    currentMeter = new CurrentMeter(25,550,150,100,675,5);

// CREATE THROTTLE, DEFINE CAB BUTTONS, and SET FUNCTIONS FOR EACH CAB
    
    int tAx=175;
    int tAy=225;
    int rX=800;
    int rY=550;

    throttleA=new Throttle(tAx,tAy,1.3);
    
    cab2004 = new CabButton(tAx-125,tAy-150,50,30,150,15,2004,throttleA);
    cab2004.setThrottleDefaults(100,50,-50,-45);
    cab2004.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab2004.setFunction(35,15,60,22,60,10,0,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab2004.setFunction(35,45,60,22,60,10,1,"Tailight",ButtonType.NORMAL,CabFunction.R_LIGHT);
    
    cab622 = new CabButton(tAx-125,tAy-100,50,30,150,15,622,throttleA);
    cab622.setThrottleDefaults(53,30,-20,-13);
    cab622.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab622.setFunction(35,15,60,22,60,10,0,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab622.setFunction(35,45,60,22,60,10,1,"Tailight",ButtonType.NORMAL,CabFunction.R_LIGHT);

    cab8601 = new CabButton(tAx-125,tAy-50,50,30,150,15,8601,throttleA);
    cab8601.setThrottleDefaults(77,46,-34,-30);
    cab8601.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab8601.setFunction(35,15,60,22,60,10,0,"Lights",ButtonType.NORMAL,CabFunction.F_LIGHT,CabFunction.R_LIGHT);

    cab6021 = new CabButton(tAx-125,tAy,50,30,150,15,6021,throttleA);
    cab6021.setThrottleDefaults(50,25,-25,-15);
    cab6021.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab6021.setFunction(35,15,60,22,60,10,0,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab6021.setFunction(35,45,60,22,60,10,1,"Tailight",ButtonType.NORMAL,CabFunction.R_LIGHT);

    cab54 = new CabButton(tAx-125,tAy+50,50,30,150,15,54,throttleA);
    cab54.setThrottleDefaults(34,14,-5,-3);
    cab54.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab54.setFunction(35,15,60,22,60,10,10,"Radiator\nFan",ButtonType.NORMAL);
    cab54.setFunction(35,45,60,22,60,10,11,"Air Fill\n/Release",ButtonType.ONESHOT);
    cab54.setFunction(35,75,60,22,60,10,14,"Passenger\nDep/Arr",ButtonType.ONESHOT);
    cab54.setFunction(35,105,60,22,60,10,18,"City\nSounds",ButtonType.ONESHOT);
    cab54.setFunction(35,135,60,22,60,10,19,"Farm\nSounds",ButtonType.ONESHOT);
    cab54.setFunction(35,165,60,22,60,10,21,"Lumber\nMill",ButtonType.ONESHOT);
    cab54.setFunction(35,195,60,22,60,10,20,"Industry\nSounds",ButtonType.ONESHOT);
    cab54.setFunction(35,225,60,22,60,10,13,"Crossing\nHorn",ButtonType.ONESHOT,CabFunction.S_HORN);
    cab54.setFunction(35,255,60,22,60,10,22,"Alternate\nHorn",ButtonType.NORMAL);
    cab54.setFunction(35,285,60,22,60,10,8,"Mute",ButtonType.NORMAL);
    cab54.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab54.setFunction(35,15,60,22,60,10,0,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab54.setFunction(35,45,60,22,60,10,1,"Bell",ButtonType.NORMAL,CabFunction.BELL);
    cab54.setFunction(35,75,60,22,60,10,2,"Horn",ButtonType.HOLD,CabFunction.HORN);
    cab54.setFunction(35,105,60,22,60,10,3,"MARS\nLight",ButtonType.REVERSE,CabFunction.D_LIGHT);
    cab54.setFunction(35,135,16,22,60,10,9,"1",ButtonType.NORMAL);
    cab54.setFunction(14,135,16,22,60,10,5,"+",ButtonType.ONESHOT);
    cab54.setFunction(56,135,16,22,60,10,6,"-",ButtonType.ONESHOT);
    cab54.setFunction(35,165,60,22,60,10,15,"Freight\nDep/Arr",ButtonType.ONESHOT);
    cab54.setFunction(35,195,60,22,60,10,16,"Facility\nShop",ButtonType.ONESHOT);
    cab54.setFunction(35,225,60,22,60,10,17,"Crew\nRadio",ButtonType.ONESHOT);
    cab54.setFunction(35,255,60,22,60,10,7,"Coupler",ButtonType.ONESHOT);
    cab54.setFunction(35,285,60,22,60,10,4,"Dynamic\nBrake",ButtonType.NORMAL);
    cab54.setFunction(35,315,60,22,60,10,12,"Brake\nSqueal",ButtonType.ONESHOT);

    cab1202 = new CabButton(tAx-125,tAy+100,50,30,150,15,1202,throttleA);
    cab1202.setThrottleDefaults(34,25,-24,-18);
    cab1202.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab1202.setFunction(35,15,60,22,60,10,0,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab1202.setFunction(35,45,60,22,60,10,1,"Tailight",ButtonType.NORMAL,CabFunction.R_LIGHT);

    cab1506 = new CabButton(tAx-125,tAy+150,50,30,150,15,1506,throttleA);
    cab1506.setThrottleDefaults(61,42,-30,-22);    
    cab1506.functionButtonWindow(220,59,70,340,backgroundColor,backgroundColor);
    cab1506.setFunction(35,15,60,22,60,10,1,"Headlight",ButtonType.NORMAL,CabFunction.F_LIGHT);
    cab1506.setFunction(35,45,60,22,60,10,0,"Tailight",ButtonType.NORMAL,CabFunction.R_LIGHT);
    cab1506.setFunction(35,75,60,22,60,10,3,"D-Lights",ButtonType.NORMAL,CabFunction.D_LIGHT);
    
//  CREATE THE IMAGE WINDOW FOR THROTTLE A (must be done AFTER throttle A is defined above)

    imageWindow=new ImageWindow(throttleA,975,450,200,50,color(200,50,50));    

// CREATE AUTO PILOT BUTTON and CLEANING CAR BUTTON (must be done AFTER cab buttons are defined above)

    autoPilot=new AutoPilotButton(325,550,100,50,30,18,"AUTO\nPILOT");
    cleaningCab=new CleaningCarButton(extrasWindow,28,80,80,120,50,40,16,"Cleaning\nCar");        

////// BEGINNING OF SAMPLE OVAL LAYOUT /////////////////////////////////////////////////////////////////////////////////////////      
      
// STEP 1: Define a LAYOUT OBJECT that creates a "frame" into which TRACKS be placed
//
//  Format is Layout(xCorner, yCorner, frameWidth, layoutWidth, layoutHeight)
//
//  xCorner:       the x-coordinate (in pixels) of the upper left corner of the layout frame
//  yCorner:       the y-coordinate (in pixels) of the upper left corner of the layout frame
//  frameWidth:    the width of the layout frame (in pixels)
//  layoutWidth:   the true width of the real layout, in whatever units you want to use (inches, mm, feet, etc)
//  layoutHeight:  the true height (depth) of the real layout, using the same units as for layoutWidth

// Note that you do no need to specify the height of the frame.  It will be automatically set to scale based on the
// other parameters.  If the resulting frameHeight is too large or small, decrease or increase the frameWidth.
    
    Layout myLayout = new Layout( 400, 100, 700, 60, 36 );            // creates a frame with upper left coordinate of (400,100), a width of 700 pixels, and real-world size of 60 inches wide by 36 inches deep
    
// STEP 2:  Create TRACK OBJECTS
// 
//  * You can create either a straight track or a curved track
//  * You can place the track directly on the layout in an absolute position, or have one end of the track connect to the end of an existing track already on the layout (i.e. a relative position)
//
// We will begin by creating a simply oval consisting of two 15" radius semi-circles connected by 24" of straight track.
//
//  Format to create a Straight Track with an Absolute Position:    Track(layoutName,x,y,length,angle)
//  
//  layoutName:    the name of the previously-created layout on which to place this track
//  x,y            the x- and y-coordinates (in real units) of one end of the track
//  length:        the length (in real units) of the track
//  angle:         the angle (in degrees from 0-360) where 0 degrees=to the right of the screen and 90 degrees=to the top of the screen
//
// IMPORTANT: The tracks defined below do not need to exactly match the individual tracks you used on your layout.  For example, you may have used
//            a single 24" straight track or six 4" straight tracks.  In either case you just need to create a single 24" straight track for the graphic layout,
//            though there is nothing wrong with creating six separate 4" straight tracks connected together.  For illustration purposes we will create
//            one 15" track connected to one 9" track to get our 24" run.  We'll see why we used these specific dimensions later below.

  Track trackA = new Track( myLayout, 18, 30, 15, 0 );      // place a straight track named trackA on myLayout with one end at an absolute positon of 18" to the right and 30" down.  Length of track is 15".  Direction is 0 degrees (to the right).
  
// Once the first track is down, we can place a second track relative to one of the end points of that first track.  This makes it easy to connect tracks without having to keep track of any absolute position.

//  Format to create a Straight Track with a Relative Position:    Track(trackName,endPoint,length)
//  
//  trackName:     the name of the previously-created track already placed on the layout
//  endPoint:      specifies which endpoint of trackName you want to connect to (0=starting endpoint, 1=ending endpoint)
//  length:        the length (in real units) of the track

  Track trackB = new Track( trackA, 1, 9 );              // connect a straight track named trackB to the "ending" endpoint of previously-created trackA.  Length of this track is 9"
  
// Now that we have our full 24" run, let's create the right-half of the oval, connected to the end of the run.

//  Format to create a Curve Track with a Relative Position:    Track(trackName,endPoint,radius,angle)
//
//  trackName:     the name of the previously-created track already placed on the layout
//  endPoint:      specifies which endpoint of trackName you want to connect to (0=starting endpoint, 1=ending endpoint)
//  radius:        radius of the curve (in real units)
//  angle:         arc angle of curve (in degrees, where a positive value indicates counter-clockwise and a negative value indicates clockwise)

  Track trackC = new Track( trackB, 1, 15, 180 );        // connect a counter-clockwise curved track namesd trackC to the "ending" endpoint of previously-created trackB.  Radius is 15" and total arc angle is 180 degrees (i.e. a 30" diameter semi-circle)

// Now let's connect on our straight tracks to the top of the semi-circle.  As before, we'll use two tracks of 15" and 9"

  Track trackD = new Track( trackC, 1, 9 );            // connect a straight track named trackD to the "ending" endpoint of previously-created trackC.  Length of this track is 9"
  Track trackE = new Track( trackD, 1, 15 );           // connect a straight track named trackE to the "ending" endpoint of previously-created trackD.  Length of this track is 15"
  
// Next we need to close the semi-circle with a 15"-radius curved track spanning 180 arc degrees.
// There are two ways we can do this:
//  
//  * We can connect this track to the ending endpoint of the top straight track we just created, and have it curve down to meet the originally-created lower straight track (i.e. it will curve counter-clockwise), OR
//  * We can connect this track to the starting endpoint of the lower straight track we originally created and have it curve up to meet the just-created top track (i.e. it will curve clockwise).
//
// Either of the two tracks below yield exactly the same graphic -- take your pick (though you probably don't need to define both!)

//  Track trackF = new Track( trackE, 1, 15, 180 );         // connect a counter-clockwise curved track named trackF to the ending endpoint previously-created trackE.  Radius is 15" and total arc angle is 180 degrees (i.e. a 30" diameter semi-circle)
  Track trackF = new Track( trackA, 0, 15, -180 );          // connect a clockwise curved track named trackF to the starting endpoint originaly-created trackA.  Radius is 15" and total arc angle is 180 degrees (i.e. a 30" diameter semi-circle)
  
// Viola - we have an oval!

// STEP 3:  Add a TURNOUT

// Recall that instead of creating our 24" straight tracks with a single 24" graphic, we used a combination of one 9" track with one 15" track.  This is because each 9" straight track is going to form the straight part of a turnout.
// We create the turnout by simply "overlaying" a curve track on top of an existing straight track.  In this case, on top of the 9" straight tracks.

// We'll start with the lower 9" straight track.  Note that the it is connected to the right semi-circle named trackC. 
// That is where we want to begin our turnout - at the beginning endpoint of trackC.
// We will use a 15" radius curve, but with a much shorter 30 degrees of arc.  Also, the track needs to curve clockwise.
// Here's how we do it:

  Track trackG = new Track( trackC, 0, 15, -30 );        // connect a clockwise curved track named trackG to the "beginning" endpoint of previously-created trackC.  Radius is 15" and total arc angle is 30 degrees

// Now that we have the graphic in place for the turnout, let's make it operational so that it flips when we click it.
// We do that by creating a TRACKBUTTON OBJECT.

// Format to create a new TrackButton object:    TrackButton(width,height,ID)
//
//  width:    the width (in pixels) of an invisible button that will be placed on the tracks to create the "clickable" area that flips the turnout
//  height:   the height (in pixels) of an invisible button that will be placed on the tracks to creates the "clickable" area that flips the turnout
//  ID:       a unique numerical identifier for this turnout (which will be used by DCC++ BASE STATION)

  TrackButton turnout1 = new TrackButton( 20, 20, 1 );      // create a new TrackButton named turnout1 with a width and height of 20 pixels, and an ID of 1.
  
// Next we have to specify that tracks that form the legs of the turnouts.  We do this with the ADDTRACK METHOD.
//
// Format to add tracks to a previously-defined TrackButton:  addTrack(trackName,position)
//
//  trackName:    the name of a previously-defined track to add as a leg to this track button
//  position:     defines whether this leg is active (=1) or inactive (=0) when the turnout is "thrown"

  turnout1.addTrack( trackB, 0 );            // add 9" straight-track named trackB to this turnout, and make it inactive when turnout is in thrown position
  turnout1.addTrack( trackG, 1 );            // add 30-degree curve track named trackG to this turnout, and make it active when turnout is in thrown position

// And that's all you need to do!  If you hover over the center point of this turnout (within a 20x20 pixel area as we specified), the cursor will change to a hand and you will be able to throw and reset the turnout.

// STEP 4:  Add siding tracks to the turnout

// Let's extend the turnout into a full siding.  We'll start with a straight track, the a curve, and then another straight.

  Track trackH = new Track( trackG, 1, 6 );            // connect a straight track named trackH to the "ending" endpoint of previously-created trackG.  Length of this track is 6"
  Track trackI = new Track( trackH, 1, 15, 30 );       // connect a counter-clockwise curved track named trackI to the ending endpoint of previously-created trackH.  Radius is 15" and total arc angle is 30 degrees
  Track trackJ = new Track( trackI, 1, 9 );            // connect a straight track named trackJ to the "ending" endpoint of previously-created trackI.  Length of this track is 9"
  
// STEP 5:  Add a ROUTEBUTTON OBJECT to the siding  
  
// As an option, we can add a siding route button to this siding.
// Siding route buttons are simply route buttons that are placed on a track.
// They are not labeled since their location on the track makes it obvious what they do.

// Format to add a Siding RouteButton object:  RouteButton(trackName,width,height)
//
//  trackName:    the name of a previously-defined track, in the middle of which this siding button will be placed
//  width:        the width (in pixels) of the siding button
//  height:       the height (in pixels) of the siding button

  RouteButton sidingButton1 = new RouteButton( trackJ, 20, 20 );        // create a siding button named sidingButton1 in the middle of trackJ.  The button is 20x20 pixels is size.
  
// Once the button is created, we now need to define which turnouts it should operate.  We do this with the ADDTRACKBUTTON METHOD:
//
// Format to add turnouts to a previously-defined RouteButton:  addTrackButton(trackButtonName,position)
//
//  trackButtonName:    the name of a previously-defined TrackButton (i.e. a turnout) to add to this RouteButton
//  position:           defines whether this turnout is thrown (=1) or not thrown (=0) when the RouteButton is pressed

  sidingButton1.addTrackButton( turnout1, 1 );      // cause turnout1 to be thrown when sidingButton1 is pressed
  
// And that's all you need to do to create a siding button.  You can now operate the turnout either directly, or with the siding button.
// Note that the siding button only operates the turnout in one direction, and it turns bright green when the siding is activated.
// If you change the direction of the turnout directly, the siding button will become dim again, indicating the siding is not active.

// As an option, you can have the layout highlight any set of tracks associated with a route when you hover over the route button.
// Let's do this for the siding button we just created using the ADDTRACK METHOD.

// Format to add tracks to a previously-defined RouteButton:  addTrack(trackName)
//
//  trackName:    the name of a previously-defined track to highlight when this route button is selected

  sidingButton1.addTrack( trackG );          // highlight the curve track from the turnout leading into this siding
  sidingButton1.addTrack( trackH );          // highlight the first straight track of the siding
  sidingButton1.addTrack( trackI );          // highlight the curve track in the middle of the siding
  sidingButton1.addTrack( trackJ );          // highlight the first straight track at the end of the siding
  
// Now when you hover over the siding route button you'll see the siding itself, including the turnout, highlighted.
// Note that turnouts that will be switched if you press the route button are shown in red.  Turnouts that are already
// set in the correct direction for the route button are shown in green.  This way you'll know exactly what turnouts will
// change if you actually press the route button.

// STEP 6:  Putting it all togther:  Create a spur off of the top straight track that connects to two different sidings.  Add siding RouteButtons to each.

  Track track01 = new Track( trackE, 0, 15, -30 );          // overlay a curve track named track01 connected to the beginning endpoint of trackE (the straight track at the top of the layout)
  TrackButton turnout2 = new TrackButton( 20, 20, 2 );      // create a new TrackButton named turnout2 with a width and height of 20 pixels, and an ID of 2.
  turnout2.addTrack( trackD, 0 );                           // add the straight track to this turnout, set for un-thrown
  turnout2.addTrack( track01, 1 );                          // add the curve track to this turnout, set for thrown
  
  Track track02 = new Track( track01, 1, 6 );               // add a straight track named track02 connected to the end of curve track01
  Track track03 = new Track ( track02, 1, 15, -60 );        // add a curve track named track03 connected to the end of straight track02
  Track track10 = new Track( track03, 1, 3 );               // add a straight track named track10 connected to the end of straight track03 --- this is the end of the first siding
  
  Track track04 = new Track( track01, 1, 15, -30 );         // overlay a curve track named track04 connected to the ending endpoint of track01
  Track track05 = new Track( track04, 1, 15, -30 );         // connect a second curve track named track0
  Track track06 = new Track( track05, 1, 3 );               // connect a small straight track to the end of this curve
  Track track07 = new Track( track06, 1, 3 );               // connect a second straight track --- this is the end of the second siding

  TrackButton turnout3 = new TrackButton( 20, 20, 3 );      // create a new TrackButton named turnout3 with a width and height of 20 pixels, and an ID of 3.
  turnout3.addTrack( track02, 0 );                          // add the straight track to this turnout, set for un-thrown
  turnout3.addTrack( track04, 1 );                          // add the curve track to this turnout, set for thrown
  
  RouteButton sidingButton2 = new RouteButton( track10, 20, 20 );        // create a siding button named sidingButton2 in the middle of track03.
  sidingButton2.addTrackButton( turnout2, 1 );                           // cause turnout2 to be thrown when sidingButton2 is pressed
  sidingButton2.addTrackButton( turnout3, 0 );                           // cause turnout3 to be un-thrown when sidingButton2 is pressed
  sidingButton2.addTrack( track01 );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  sidingButton2.addTrack( track02 );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  sidingButton2.addTrack( track03 );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  sidingButton2.addTrack( track10 );                                     // add the tracks of this siding to be highlighted when hovering over this route buton

  RouteButton sidingButton3 = new RouteButton( track07, 20, 20 );        // create a siding button named sidingButton3 in the middle of track07.
  sidingButton3.addTrackButton( turnout2, 1 );                           // cause turnout2 to be thrown when sidingButton2 is pressed
  sidingButton3.addTrackButton( turnout3, 1 );                           // cause turnout3 to be thrown when sidingButton2 is pressed
  sidingButton3.addTrack( track01 );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  sidingButton3.addTrack( track04 );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  sidingButton3.addTrack( track05 );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  sidingButton3.addTrack( track06 );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  sidingButton3.addTrack( track07 );                                     // add the tracks of this siding to be highlighted when hovering over this route buton

// STEP 7:  How about adding a Standalone RouteButton so that with one click we can set all the turnouts to be aligned with the main oval?

// Format to create a Standalone RouteButton:  RouteButton(x,y,width,height,label)
//
//  x,y:     the x- and y-coordinate (in pixels) of the center of the RouteButton
//  width:   the width (in pixels) of the RouteButton
//  height:  the height (in pixels) of the RouteButton
//  label:   a descriptive label for the RouteButton

  RouteButton setOvalButton = new RouteButton( 600, 500, 70, 30, "Set Oval" );        // create a standalone route button named "Set Oval" at (x,y)=(600,500).  Width=70 pixels, Height=30 pixels

// Turnouts are add to standalone RouteButtons in the exact same way as for siding RouteButtons

  setOvalButton.addTrackButton( turnout1, 0 );            // cause turnout1 to be un-thrown when setOvalButton is pressed
  setOvalButton.addTrackButton( turnout2, 0 );            // cause turnout2 to be un-thrown when setOvalButton is pressed
  
// Similarly, you can highlight certin tracks as part of the route button

  setOvalButton.addTrack( trackA );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  setOvalButton.addTrack( trackB );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  setOvalButton.addTrack( trackC );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  setOvalButton.addTrack( trackD );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  setOvalButton.addTrack( trackE );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  setOvalButton.addTrack( trackF );                                     // add the tracks of this siding to be highlighted when hovering over this route buton
  
// Note how this standalone siding button is lit only when all of the turnouts are set in the required directions

// Congratulations!  You've completed an oval layout with three turnouts, three sidings, and four routes.

////// END OF SAMPLE LAYOUT /////////////////////////////////////////////////////////////////////////////////////////

  } // Initialize

//////////////////////////////////////////////////////////////////////////