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
  XML dccStatusXML, serialPortXML, sensorButtonsXML, autoPilotXML, cabDefaultsXML;
  
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
  
  ArduinoSerial     aPort;
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

    aPort=new ArduinoSerial();
    
// READ, OR CREATE IF NEEDED, XML DCC STATUS FILE
    
    dccStatusXML=loadXML(STATUS_FILE);
    if(dccStatusXML==null){
      dccStatusXML=new XML("dccStatus");
    }

    serialPortXML=dccStatusXML.getChild("serialPort");
    if(serialPortXML==null){
      serialPortXML=dccStatusXML.addChild("serialPort");
      serialPortXML.setContent("Emulator");
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
    new RectButton(progWindow,250,30,210,30,40,color(0),18,"Programming Track",1);        
    
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
    new RectButton(extrasWindow,260,80,120,50,85,color(0),16,"Sound\nEffects",0);        

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

    msgBoxMain=new MessageBox(width/2,12,width,25,color(200),20,"Searching for Base Station: "+serialPortXML.getContent(),color(30,30,150));
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
      
// CREATE MAIN LAYOUT AND DEFINE ALL TRACKS
    
    layout=new Layout(325,50,1000,80*25.4,36*25.4);
    
    Track bridgeA = new Track(layout,20,450,62,90);
    Track bridgeB = new Track(bridgeA,1,348,-90);
    Track bridgeC = new Track(bridgeB,1,399);
    Track t5A = new Track(bridgeC,1,126);
    Track loop3A = new Track(t5A,1,682);
    Track loop3B = new Track(loop3A,1,381,-180);
    Track loop3C = new Track(loop3B,1,124);
    Track t20A2 = new Track(loop3C,1,126);
    Track t20B2 = new Track(loop3C,1,481,15);
    Track t20B1 = new Track(t20B2,1,481,-15);
    Track loop2A3A = new Track(t20A2,1,120);
    Track t30A1 = new Track(loop2A3A,1,126);
    Track t30A2 = new Track(t30A1,1,126);
    Track t30B1 = new Track(loop2A3A,1,481,-15);
    Track t30B4 = new Track(t30B1,1,481,15);
    Track loop2C = new Track(t30A2,1,122);
    Track t10A3 = new Track(loop2C,1,126);
    Track t10B3 = new Track(loop2C,1,481,15);
    Track t10A4 = new Track(t10A3,1,126);
    Track t10B2 = new Track(t10B3,1,481,-15);
    Track loop2D = new Track(t10A4,1,62);
    Track loop2E = new Track(loop2D,1,315,-165);
    Track loop2F = new Track(loop2E,1,128);
    Track loop2G = new Track(loop2F,1,315,-15);
    Track loop2H = new Track(loop2G,1,742);
    Track t50A2 = new Track(loop2H,1,126);
    Track loop2A = new Track(t50A2,1,315,-180);
    Track loop2B = new Track(loop2A,1,308);
    Track t30A3 = new Track(loop2B,1,126);
    Track t30A4 = new Track(t30A3,1,126);
    Track t30B3 = new Track(loop2B,1,481,15);
    Track t30B2 = new Track(t30B3,1,481,-15);
    Track loop1A2A = new Track(t30A4,1,60);
    Track t40A1 = new Track(loop1A2A,1,126);
    Track loop1B = new Track(t40A1,1,248);
    Track loop1C = new Track(loop1B,1,282,-165);
    Track loop1D = new Track(loop1C,1,128);
    Track loop1E = new Track(loop1D,1,282,-15);
    Track t4A = new Track(loop1E,1,126);
    Track t4B = new Track(loop1E,1,481,-15);
    Track loop1F = new Track(t4A,1,494);
    Track t50A1 = new Track(loop1F,1,126);
    Track t50B1 = new Track(loop1F,1,481,15);
    Track t50B2 = new Track(t50B1,1,481,-15);
    Track loop1G = new Track(t50A1,1,122);
    Track loop1H = new Track(loop1G,1,282,-180);
    Track loop1I = new Track(loop1H,1,62);
    Track t1A = new Track(loop1I,1,126);
    Track t1B = new Track(loop1I,1,481,-15);
    Track loop1A = new Track(t1A,1,308);
    Track t40A2 = new Track(loop1A,1,126);
    Track t40B2 = new Track(loop1A,1,481,15);
    Track t40B1 = new Track(t40B2,1,481,-15);
    Track s1A = new Track(t40A2,1,60);
    Track s1B = new Track(s1A,1,481,-15);
    Track s1C = new Track(s1B,1,339);
    Track s1 = new Track(s1C,1,50);
    Track loop3D = new Track(t20B1,1,370);
    Track t20A1 = new Track(loop3D,0,126);
    Track t10A1 = new Track(loop3D,1,126);
    Track t10B1 = new Track(loop3D,1,481,-15);
    Track t10B4 = new Track(t10B1,1,481,15);
    Track t10A2 = new Track(t10A1,1,126);
    Track loop3E = new Track(t10A2,1,62);
    Track loop3F = new Track(loop3E,1,381,-180);
    Track loop3G = new Track(loop3F,1,124);
    Track loop3H = new Track(loop3G,1,481,15);
    Track t5B = new Track(loop3H,1,481,-15);
    Track s7A = new Track(t20A1,1,337);
    Track s7B = new Track(s7A,1,348,90);
    Track s7C = new Track(s7B,1,124);
    Track s7D = new Track(s7C,1,481,15);
    Track s7E = new Track(s7D,1,124);
    Track s7 = new Track(s7E,1,62);
    Track t2A = new Track(t1B,1,126);
    Track t2B = new Track(t1B,1,481,-15);
    Track s2_3_4_5A = new Track(t2A,1,64);
    Track t3A = new Track(s2_3_4_5A,1,126);
    Track t3B = new Track(s2_3_4_5A,1,481,15);
    Track s2A = new Track(t3B,1,30);
    Track s2B = new Track(s2A,1,481,15);
    Track s2C = new Track(s2B,1,481,-30);
    Track s2D = new Track(s2C,1,248);
    Track s2 = new Track(s2D,1,50);
    Track t6A = new Track(t3A,1,126);
    Track t6B = new Track(t3A,1,481,-15);
    Track s3A = new Track(t6A,1,556);
    Track s3 = new Track(s3A,1,50);
    Track t9A = new Track(t6B,1,126);
    Track t9B = new Track(t6B,1,481,15);
    Track s4A = new Track(t9B,1,479);
    Track s4 = new Track(s4A,1,50);
    Track s5A = new Track(t9A,1,481,15);
    Track s5B = new Track(s5A,1,341);
    Track s5 = new Track(s5B,1,50);
    Track rLoopA = new Track(t4B,1,282,-45);
    Track rLoopB = new Track(rLoopA,1,87);
    Track t7A = new Track(rLoopB,1,126);
    Track t7B = new Track(rLoopB,1,481,15);
    Track rLoopC = new Track(t7A,1,481,15);
    Track rLoopD = new Track(rLoopC,1,425,15);
    Track s6A = new Track(t7B,1,60);
    Track s6B = new Track(s6A,1,282,45);
    Track s6C = new Track(s6B,1,481,30);
    Track s6D = new Track(s6C,1,188);
    Track s6 = new Track(s6D,1,50);
    Track bridgeD = new Track(bridgeA,0,348,60);
    
// CREATE SECOND LAYOUT FOR SKY BRIDGE AND DEFINE TRACKS
    
    layout2=new Layout(325,500,400,80*25.4,36*25.4);
    layoutBridge=new Layout(layout2);
    
    Track bridgeE = new Track(bridgeD,1,348,60,layoutBridge);
    Track bridgeF = new Track(bridgeE,1,248);
    Track t8A = new Track(bridgeF,1,200);
    Track t8B = new Track(bridgeF,1,400,-35);
    Track bridgeG = new Track(t8A,1,618);
    Track bridgeH = new Track(bridgeG,1,282,-226);
    Track bridgeI = new Track(bridgeH,1,558);
    
// DEFINE SENSORS, MAP TO ARDUINO NUMBERS, AND INDICATE THEIR TRACK LOCATIONS

    new TrackSensor(loop3B,1,30,20,20,1,false);          // mappings from Sensor numbers (1..N) to Arduino Pins
    new TrackSensor(t50A2,1,315,-174,20,20,2,false);
    new TrackSensor(loop2D,1,315,-47,20,20,3,false);
    new TrackSensor(loop1B,1,282,-45,20,20,4,false);
    new TrackSensor(loop3E,1,381,-45,20,20,5,false);
    new TrackSensor(bridgeA,1,348,-10,20,20,6,false);
    new TrackSensor(s1A,1,481,-5,20,20,7,true);
    new TrackSensor(s2B,1,481,-5,20,20,8,true);
    new TrackSensor(t6A,1,175,20,20,9,true);
    new TrackSensor(s6A,1,282,10,20,20,10,true);
    new TrackSensor(loop1G,1,282,-137,20,20,11,false);
    new TrackSensor(t9B,1,100,20,20,12,true);
    new TrackSensor(s5A,1,30,20,20,13,true);
    new TrackSensor(s7A,1,348,50,20,20,14,true);
    
// CREATE TURNOUT BUTTONS and ADD TRACKS FOR EACH TURNOUT

    tButton1 = new TrackButton(20,20,1);
    tButton1.addTrack(t1A,0);
    tButton1.addTrack(t1B,1);
    
    tButton2 = new TrackButton(20,82,2);
    tButton2.addTrack(t2A,0);
    tButton2.addTrack(t2B,1);
    
    tButton3 = new TrackButton(20,20,3);
    tButton3.addTrack(t3A,0);
    tButton3.addTrack(t3B,1);
    
    tButton4 = new TrackButton(20,20,4);
    tButton4.addTrack(t4A,0);
    tButton4.addTrack(t4B,1);

    tButton5 = new TrackButton(20,20,5);
    tButton5.addTrack(t5A,0);
    tButton5.addTrack(t5B,1);
       
    tButton6 = new TrackButton(20,20,6);
    tButton6.addTrack(t6A,0);
    tButton6.addTrack(t6B,1);

    tButton7 = new TrackButton(20,20,7);
    tButton7.addTrack(t7A,0);
    tButton7.addTrack(t7B,1);

    tButton8 = new TrackButton(20,20,8);
    tButton8.addTrack(t8A,0);
    tButton8.addTrack(t8B,1);
    
    tButton9 = new TrackButton(20,20,9);
    tButton9.addTrack(t9A,0);
    tButton9.addTrack(t9B,1);

    tButton10 = new TrackButton(20,20,10);
    tButton10.addTrack(t10A1,0);
    tButton10.addTrack(t10A2,0);
    tButton10.addTrack(t10A3,0);
    tButton10.addTrack(t10A4,0);
    tButton10.addTrack(t10B1,1);
    tButton10.addTrack(t10B2,1);
    tButton10.addTrack(t10B3,1);
    tButton10.addTrack(t10B4,1);

    tButton20 = new TrackButton(20,20,20);
    tButton20.addTrack(t20A1,0);
    tButton20.addTrack(t20A2,0);
    tButton20.addTrack(t20B1,1);
    tButton20.addTrack(t20B2,1);

    tButton30 = new TrackButton(20,20,30);
    tButton30.addTrack(t30A1,0);
    tButton30.addTrack(t30A2,0);
    tButton30.addTrack(t30A3,0);
    tButton30.addTrack(t30A4,0);
    tButton30.addTrack(t30B1,1);
    tButton30.addTrack(t30B2,1);
    tButton30.addTrack(t30B3,1);
    tButton30.addTrack(t30B4,1);

    tButton40 = new TrackButton(20,20,40);
    tButton40.addTrack(t40A1,0);
    tButton40.addTrack(t40A2,0);
    tButton40.addTrack(t40B1,1);
    tButton40.addTrack(t40B2,1);

    tButton50 = new TrackButton(20,20,50);
    tButton50.addTrack(t50A1,0);
    tButton50.addTrack(t50A2,0);
    tButton50.addTrack(t50B1,1);
    tButton50.addTrack(t50B2,1);

// CREATE ROUTE BUTTONS and ADD TRACKS and TURNOUT BUTTONS

    rButton1 = new RouteButton(s1,20,20);
    rButton1.addTrackButton(tButton40,0);
    rButton1.addTrackButton(tButton1,0);
    rButton1.addTrack(t1A);
    rButton1.addTrack(loop1A);
    rButton1.addTrack(t40A2);
    rButton1.addTrack(s1A);
    rButton1.addTrack(s1B);
    rButton1.addTrack(s1C);
    rButton1.addTrack(s1);
    
    rButton2 = new RouteButton(s2,20,20);
    rButton2.addTrackButton(tButton3,1);
    rButton2.addTrackButton(tButton2,0);
    rButton2.addTrackButton(tButton1,1);
    rButton2.addTrack(t1B);
    rButton2.addTrack(t2A);
    rButton2.addTrack(s2_3_4_5A);
    rButton2.addTrack(t3B);
    rButton2.addTrack(s2A);
    rButton2.addTrack(s2B);
    rButton2.addTrack(s2C);
    rButton2.addTrack(s2D);
    rButton2.addTrack(s2);

    rButton3 = new RouteButton(s3,20,20);
    rButton3.addTrackButton(tButton6,0);
    rButton3.addTrackButton(tButton3,0);
    rButton3.addTrackButton(tButton2,0);
    rButton3.addTrackButton(tButton1,1);
    rButton3.addTrack(t1B);
    rButton3.addTrack(t2A);
    rButton3.addTrack(s2_3_4_5A);
    rButton3.addTrack(t3A);
    rButton3.addTrack(t6A);
    rButton3.addTrack(s3A);
    rButton3.addTrack(s3);

    rButton4 = new RouteButton(s4,20,20);
    rButton4.addTrackButton(tButton9,1);
    rButton4.addTrackButton(tButton6,1);
    rButton4.addTrackButton(tButton3,0);
    rButton4.addTrackButton(tButton2,0);
    rButton4.addTrackButton(tButton1,1);
    rButton4.addTrack(t1B);
    rButton4.addTrack(t2A);
    rButton4.addTrack(s2_3_4_5A);
    rButton4.addTrack(t3A);
    rButton4.addTrack(t6B);
    rButton4.addTrack(t9B);
    rButton4.addTrack(s4A);
    rButton4.addTrack(s4);

    rButton5 = new RouteButton(s5,20,20);
    rButton5.addTrackButton(tButton9,0);
    rButton5.addTrackButton(tButton6,1);
    rButton5.addTrackButton(tButton3,0);
    rButton5.addTrackButton(tButton2,0);
    rButton5.addTrackButton(tButton1,1);
    rButton5.addTrack(t1B);
    rButton5.addTrack(t2A);
    rButton5.addTrack(s2_3_4_5A);
    rButton5.addTrack(t3A);
    rButton5.addTrack(t6B);
    rButton5.addTrack(t9A);
    rButton5.addTrack(s5A);
    rButton5.addTrack(s5B);
    rButton5.addTrack(s5);

    rButton6 = new RouteButton(s6,20,20);
    rButton6.addTrackButton(tButton7,1);
    rButton6.addTrackButton(tButton4,1);
    rButton6.addTrack(t7B);
    rButton6.addTrack(t4B);
    rButton6.addTrack(rLoopA);
    rButton6.addTrack(rLoopB);
    rButton6.addTrack(s6A);
    rButton6.addTrack(s6B);
    rButton6.addTrack(s6C);
    rButton6.addTrack(s6D);
    rButton6.addTrack(s6);    

    rButton7 = new RouteButton(s7,20,20);
    rButton7.addTrackButton(tButton20,0);
    rButton7.addTrackButton(tButton10,0);
    rButton7.addTrack(t20A1);
    rButton7.addTrack(t10A1);
    rButton7.addTrack(t10A2);
    rButton7.addTrack(s7A);
    rButton7.addTrack(s7B);
    rButton7.addTrack(s7C);
    rButton7.addTrack(s7D);
    rButton7.addTrack(s7E);
    rButton7.addTrack(s7);
    rButton7.addTrack(loop3D);

    rButton10 = new RouteButton(rX,rY,80,40,"Inner\nLoop");
    rButton10.addTrackButton(tButton50,0);
    rButton10.addTrackButton(tButton1,0);
    rButton10.addTrackButton(tButton40,1);
    rButton10.addTrackButton(tButton4,0);    
    rButton10.addTrack(t40B1);
    rButton10.addTrack(t40B2);
    rButton10.addTrack(t4A);
    rButton10.addTrack(t50A1);
    rButton10.addTrack(t1A);    
    rButton10.addTrack(loop1A);
    rButton10.addTrack(loop1B);
    rButton10.addTrack(loop1C);
    rButton10.addTrack(loop1D);
    rButton10.addTrack(loop1E);
    rButton10.addTrack(loop1F);
    rButton10.addTrack(loop1G);
    rButton10.addTrack(loop1H);
    rButton10.addTrack(loop1I);

    rButton11 = new RouteButton(rX+200,rY,80,40,"Middle\nLoop");
    rButton11.addTrackButton(tButton50,0);
    rButton11.addTrackButton(tButton30,1);
    rButton11.addTrackButton(tButton10,0);
    rButton11.addTrack(t50A2);
    rButton11.addTrack(t30B3);
    rButton11.addTrack(t30B2);
    rButton11.addTrack(t10A3);
    rButton11.addTrack(t10A4);    
    rButton11.addTrack(loop2A);
    rButton11.addTrack(loop2B);
    rButton11.addTrack(loop2C);
    rButton11.addTrack(loop2D);
    rButton11.addTrack(loop2E);
    rButton11.addTrack(loop2F);
    rButton11.addTrack(loop2G);
    rButton11.addTrack(loop2H);

    rButton12 = new RouteButton(rX+400,rY,80,40,"Outer\nLoop");
    rButton12.addTrackButton(tButton20,1);
    rButton12.addTrackButton(tButton5,1);
    rButton12.addTrackButton(tButton10,0);
    rButton12.addTrack(t20B2);
    rButton12.addTrack(t20B1);
    rButton12.addTrack(t10A1);
    rButton12.addTrack(t10A2);
    rButton12.addTrack(t5B);    
    rButton12.addTrack(loop3A);
    rButton12.addTrack(loop3B);
    rButton12.addTrack(loop3C);
    rButton12.addTrack(loop3D);
    rButton12.addTrack(loop3E);
    rButton12.addTrack(loop3F);
    rButton12.addTrack(loop3G);
    rButton12.addTrack(loop3H);
    
    rButton13 = new RouteButton(rX+100,rY,80,40,"Inner/Mid");
    rButton13.addTrackButton(tButton50,1);
    rButton13.addTrackButton(tButton30,0);
    rButton13.addTrackButton(tButton40,0);
    rButton13.addTrackButton(tButton4,0);    
    rButton13.addTrack(t40A1);
    rButton13.addTrack(loop1B);
    rButton13.addTrack(loop1C);
    rButton13.addTrack(loop1D);
    rButton13.addTrack(loop1E);
    rButton13.addTrack(t4A);
    rButton13.addTrack(loop1F);
    rButton13.addTrack(t50B1);
    rButton13.addTrack(t50B2);
    rButton13.addTrack(loop2A);
    rButton13.addTrack(loop2B);
    rButton13.addTrack(t30A3);
    rButton13.addTrack(t30A4);    
    rButton13.addTrack(loop1A2A);

    rButton14 = new RouteButton(rX+300,rY,80,40,"Mid/Outer");
    rButton14.addTrackButton(tButton5,1);
    rButton14.addTrackButton(tButton20,0);
    rButton14.addTrackButton(tButton30,0);
    rButton14.addTrackButton(tButton10,1);
    rButton14.addTrack(t5B);
    rButton14.addTrack(loop3A);
    rButton14.addTrack(loop3B);
    rButton14.addTrack(loop3C);
    rButton14.addTrack(t20A2);
    rButton14.addTrack(loop2A3A);
    rButton14.addTrack(t30A1);
    rButton14.addTrack(t30A2);
    rButton14.addTrack(loop2C);
    rButton14.addTrack(t10B3);
    rButton14.addTrack(t10B2);
    rButton14.addTrack(loop3E);
    rButton14.addTrack(loop3F);
    rButton14.addTrack(loop3G);
    rButton14.addTrack(loop3H);    

    rButtonR1 = new RouteButton(rX,rY+60,80,40,"Reverse+");
    rButtonR1.addTrackButton(tButton4,1);
    rButtonR1.addTrackButton(tButton7,0);
    rButtonR1.addTrackButton(tButton1,0);
    rButtonR1.addTrack(t4B);
    rButtonR1.addTrack(rLoopA);
    rButtonR1.addTrack(rLoopB);
    rButtonR1.addTrack(t7A);
    rButtonR1.addTrack(t1A);

    rButtonR2 = new RouteButton(rX+100,rY+60,80,40,"Reverse-");
    rButtonR2.addTrackButton(tButton1,1);
    rButtonR2.addTrackButton(tButton2,1);
    rButtonR2.addTrackButton(tButton4,0);
    rButtonR2.addTrack(t4A);
    rButtonR2.addTrack(t1B);
    rButtonR2.addTrack(t2B);
    rButtonR2.addTrack(rLoopC);    
    rButtonR2.addTrack(rLoopD);    

    rButton15 = new RouteButton(rX+200,rY+60,80,40,"Mid+Outer");
    rButton15.addTrackButton(tButton5,1);
    rButton15.addTrackButton(tButton10,1);
    rButton15.addTrackButton(tButton20,1);
    rButton15.addTrackButton(tButton30,1);
    rButton15.addTrackButton(tButton50,0);
    rButton15.addTrack(t20B2);
    rButton15.addTrack(t20B1);
    rButton15.addTrack(t10B1);
    rButton15.addTrack(t10B2);
    rButton15.addTrack(t5B);    
    rButton15.addTrack(loop3A);
    rButton15.addTrack(loop3B);
    rButton15.addTrack(loop3C);
    rButton15.addTrack(loop3D);
    rButton15.addTrack(loop3E);
    rButton15.addTrack(loop3F);
    rButton15.addTrack(loop3G);
    rButton15.addTrack(loop3H);
    rButton15.addTrack(t50A2);
    rButton15.addTrack(t30B3);
    rButton15.addTrack(t30B2);
    rButton15.addTrack(t10B3);
    rButton15.addTrack(t10B4);    
    rButton15.addTrack(loop2A);
    rButton15.addTrack(loop2B);
    rButton15.addTrack(loop2C);
    rButton15.addTrack(loop2D);
    rButton15.addTrack(loop2E);
    rButton15.addTrack(loop2F);
    rButton15.addTrack(loop2G);
    rButton15.addTrack(loop2H);

    rButton16 = new RouteButton(rX+300,rY+60,80,40,"In+Outer");
    rButton16.addTrackButton(tButton4,0);
    rButton16.addTrackButton(tButton5,1);
    rButton16.addTrackButton(tButton10,1);
    rButton16.addTrackButton(tButton20,0);
    rButton16.addTrackButton(tButton30,1);
    rButton16.addTrackButton(tButton40,0);
    rButton16.addTrackButton(tButton50,1);
    rButton16.addTrack(t40A1);
    rButton16.addTrack(loop1B);
    rButton16.addTrack(loop1C);
    rButton16.addTrack(loop1D);
    rButton16.addTrack(loop1E);
    rButton16.addTrack(t4A);
    rButton16.addTrack(loop1F);
    rButton16.addTrack(t50B1);
    rButton16.addTrack(t50B2);
    rButton16.addTrack(loop2A);
    rButton16.addTrack(loop2B);
    rButton16.addTrack(t30B1);
    rButton16.addTrack(t30B2);    
    rButton16.addTrack(t30B3);
    rButton16.addTrack(t30B4);    
    rButton16.addTrack(loop1A2A);
    rButton16.addTrack(t5B);
    rButton16.addTrack(loop3A);
    rButton16.addTrack(loop3B);
    rButton16.addTrack(loop3C);
    rButton16.addTrack(t20A2);
    rButton16.addTrack(loop2A3A);
    rButton16.addTrack(loop2C);
    rButton16.addTrack(t10B3);
    rButton16.addTrack(t10B2);
    rButton16.addTrack(loop3E);
    rButton16.addTrack(loop3F);
    rButton16.addTrack(loop3G);
    rButton16.addTrack(loop3H);    
    
    rButton17 = new RouteButton(rX,rY+120,80,40,"Double X");
    rButton17.addTrackButton(tButton5,0);
    rButton17.addTrackButton(tButton20,0);
    rButton17.addTrackButton(tButton30,1);
    rButton17.addTrackButton(tButton40,0);
    rButton17.addTrackButton(tButton50,0);
    rButton17.addTrackButton(tButton4,1);
    rButton17.addTrackButton(tButton7,0);
    rButton17.addTrackButton(tButton1,0);
    rButton17.addTrack(t4B);
    rButton17.addTrack(rLoopA);
    rButton17.addTrack(rLoopB);
    rButton17.addTrack(t7A);
    rButton17.addTrack(t1A);
    rButton17.addTrack(loop1B);
    rButton17.addTrack(loop1C);
    rButton17.addTrack(loop1D);
    rButton17.addTrack(loop1E);
    rButton17.addTrack(loop1F);
    rButton17.addTrack(loop1G);
    rButton17.addTrack(loop1H);
    rButton17.addTrack(loop1I);
    rButton17.addTrack(t50A1);
    rButton17.addTrack(t40A1);
    rButton17.addTrack(loop1A2A);
    rButton17.addTrack(t30B4);
    rButton17.addTrack(t30B1);
    rButton17.addTrack(loop3A);
    rButton17.addTrack(loop3B);
    rButton17.addTrack(loop3C);
    rButton17.addTrack(t20A2);
    rButton17.addTrack(loop2A3A);
    rButton17.addTrack(t5A);
    rButton17.addTrack(bridgeA);
    rButton17.addTrack(bridgeB);
    rButton17.addTrack(bridgeC);
    rButton17.addTrack(bridgeD);
    rButton17.addTrack(bridgeE);
    rButton17.addTrack(bridgeF);
    rButton17.addTrack(bridgeG);
    rButton17.addTrack(bridgeH);
    rButton17.addTrack(bridgeI);

    rButtonSpiral = new RouteButton(rX+100,rY+120,80,40,"Spiral");
    rButtonSpiral.addTrackButton(tButton4,1);
    rButtonSpiral.addTrackButton(tButton5,0);
    rButtonSpiral.addTrackButton(tButton7,0);
    rButtonSpiral.addTrackButton(tButton1,0);
    rButtonSpiral.addTrackButton(tButton10,0);
    rButtonSpiral.addTrackButton(tButton20,0);
    rButtonSpiral.addTrackButton(tButton30,0);
    rButtonSpiral.addTrackButton(tButton40,0);
    rButtonSpiral.addTrackButton(tButton50,0);    
    rButtonSpiral.addTrack(t4B);
    rButtonSpiral.addTrack(rLoopA);
    rButtonSpiral.addTrack(rLoopB);
    rButtonSpiral.addTrack(t7A);
    rButtonSpiral.addTrack(t1A);
    rButtonSpiral.addTrack(loop1B);
    rButtonSpiral.addTrack(loop1C);
    rButtonSpiral.addTrack(loop1D);
    rButtonSpiral.addTrack(loop1E);
    rButtonSpiral.addTrack(loop1F);
    rButtonSpiral.addTrack(loop1G);
    rButtonSpiral.addTrack(loop1H);
    rButtonSpiral.addTrack(loop1I);
    rButtonSpiral.addTrack(t50A1);
    rButtonSpiral.addTrack(t40A1);
    rButtonSpiral.addTrack(loop1A2A);
    rButtonSpiral.addTrack(t30A4);
    rButtonSpiral.addTrack(t30A3);
    rButtonSpiral.addTrack(t50A2);
    rButtonSpiral.addTrack(loop2A);
    rButtonSpiral.addTrack(loop2B);
    rButtonSpiral.addTrack(loop2C);
    rButtonSpiral.addTrack(loop2D);
    rButtonSpiral.addTrack(loop2E);
    rButtonSpiral.addTrack(loop2F);
    rButtonSpiral.addTrack(loop2G);
    rButtonSpiral.addTrack(loop2H);
    rButtonSpiral.addTrack(t10A3);
    rButtonSpiral.addTrack(t10A4);
    rButtonSpiral.addTrack(t30A1);
    rButtonSpiral.addTrack(t30A2);
    rButtonSpiral.addTrack(loop2A3A);
    rButtonSpiral.addTrack(t20A2);
    rButtonSpiral.addTrack(loop3A);
    rButtonSpiral.addTrack(loop3B);
    rButtonSpiral.addTrack(loop3C);
    rButtonSpiral.addTrack(t5A);
    rButtonSpiral.addTrack(bridgeA);
    rButtonSpiral.addTrack(bridgeB);
    rButtonSpiral.addTrack(bridgeC);
    rButtonSpiral.addTrack(bridgeD);
    rButtonSpiral.addTrack(bridgeE);
    rButtonSpiral.addTrack(bridgeF);
    rButtonSpiral.addTrack(bridgeG);
    rButtonSpiral.addTrack(bridgeH);
    rButtonSpiral.addTrack(bridgeI);

    rButtonReset = new RouteButton(rX+400,rY+120,80,40,"RESET");
    rButtonReset.addTrackButton(tButton40,0);
    rButtonReset.addTrackButton(tButton3,0);
    rButtonReset.addTrackButton(tButton2,0);
    rButtonReset.addTrackButton(tButton8,0);
    rButtonReset.addTrackButton(tButton10,0);
    rButtonReset.addTrackButton(tButton20,0);
    rButtonReset.addTrackButton(tButton9,0);
    rButtonReset.addTrackButton(tButton4,0);
    rButtonReset.addTrackButton(tButton1,0);
    rButtonReset.addTrackButton(tButton5,0);
    rButtonReset.addTrackButton(tButton50,0);
    rButtonReset.addTrackButton(tButton6,0);
    rButtonReset.addTrackButton(tButton7,0);
    rButtonReset.addTrackButton(tButton30,0);
    rButtonReset.addTrack(t1A);
    rButtonReset.addTrack(t2A);
    rButtonReset.addTrack(t3A);
    rButtonReset.addTrack(t4A);
    rButtonReset.addTrack(t5A);
    rButtonReset.addTrack(t6A);
    rButtonReset.addTrack(t7A);
    rButtonReset.addTrack(t8A);
    rButtonReset.addTrack(t9A);
    rButtonReset.addTrack(t10A1);
    rButtonReset.addTrack(t10A2);
    rButtonReset.addTrack(t10A3);
    rButtonReset.addTrack(t10A4);
    rButtonReset.addTrack(t20A1);
    rButtonReset.addTrack(t20A2);
    rButtonReset.addTrack(t30A1);
    rButtonReset.addTrack(t30A2);
    rButtonReset.addTrack(t30A3);
    rButtonReset.addTrack(t30A4);
    rButtonReset.addTrack(t40A1);
    rButtonReset.addTrack(t40A2);
    rButtonReset.addTrack(t50A1);
    rButtonReset.addTrack(t50A2);
    
    rButtonBridge = new RouteButton(bridgeA,20,20);
    rButtonBridge.addTrackButton(tButton5,0);
    rButtonBridge.addTrackButton(tButton8,0);
    rButtonBridge.addTrack(t5A);
    rButtonBridge.addTrack(bridgeA);
    rButtonBridge.addTrack(bridgeB);
    rButtonBridge.addTrack(bridgeC);
    rButtonBridge.addTrack(bridgeD);
    rButtonBridge.addTrack(bridgeE);
    rButtonBridge.addTrack(bridgeF);
    rButtonBridge.addTrack(bridgeG);
    rButtonBridge.addTrack(bridgeH);
    rButtonBridge.addTrack(bridgeI);
    rButtonBridge.addTrack(t8A);    
    
    cab622.setSidingDefaults(rButton6,4,10);      // must set default sidings AFTER rButtons are defined above
    cab6021.setSidingDefaults(rButton1,11,7);
    cab54.setSidingDefaults(rButton2,11,8);
    cab1506.setSidingDefaults(rButton3,11,9);
    cab8601.setSidingDefaults(rButton4,11,12);
    cab1202.setSidingDefaults(rButton5,11,13);
    cab2004.setSidingDefaults(rButton7,5,14);
    
  } // Initialize

//////////////////////////////////////////////////////////////////////////