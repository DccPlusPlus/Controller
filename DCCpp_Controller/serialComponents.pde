//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Serial Components
//
//  All classes and methods related to serial communication to and from
//  the DCC++ Base Station
//
//  PortScanButton  -  function depends on button label as follows:
//
//                    "SCAN"      - create a list all serial ports on the computer
//                     ">"        - scroll forward through the list
//                     "<"        - scroll backwards through the list
//                     "CONNECT"  - attempt to connect to a DCC++ Base Station
//
//                  - the default configuration of DCC++ Controller defines a
//                    Serial Window that includes all of these components
//
//  ArduinoPort    -  defines a generic port connection to the DCC++ Base Station
//                 -  extends Processing's normal Serial class by adding an
//                    Ethernet or WiFi Client connection at port 2560 as well as 
//                    a "simulation" function so that DCC++ Controller can be run
//                    in "emulator" mode without actually establishing a connection
//                    to the DCC++ Base Station
//                 -  ideal for developing, testing, and demonstrating DCC++ Controller
//                    without an Arduino
//                 -  also adds functionality that echos to a pre-specified text box all
//                    text that is written to the DCC++ Base Station
//                 -  the default configuration of DCC++ Controller defines a
//                    Diagnostic Window that includes this text box and is useful for
//                    observing the exact commands DCC++ Controller sends to the
//                    DCC++ Base Station
//
//////////////////////////////////////////////////////////////////////////
//  DCC Component: PortScanButton
//////////////////////////////////////////////////////////////////////////

class PortScanButton extends RectButton{
  boolean isComplete;
  
  PortScanButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(255), fontSize, bText, ButtonType.ONESHOT);
  } // AccessoryButton

//////////////////////////////////////////////////////////////////////////

  void pressed(){
    isComplete=false;
    super.pressed();
  }
  
//////////////////////////////////////////////////////////////////////////

  void scan(){
    String[] emulator = {"Emulator"};
    String[] serverList=splitTokens(serverListXML.getContent());

    
    aPort.portList=concat(emulator,Serial.list());    
    aPort.portList=concat(aPort.portList,serverList);
    
    aPort.displayedPort=0;
    portBox.setMessage(aPort.portList[aPort.displayedPort],aPort.portList[aPort.displayedPort].equals(arduinoPortXML.getContent())?color(50,150,50):color(50,50,200));
    portNumBox.setMessage("Port "+(aPort.displayedPort+1)+" of "+aPort.portList.length,color(50,50,50));
    
  } // scan

//////////////////////////////////////////////////////////////////////////

  void turnOff(){
    String[] emulator = {"Emulator"};
    
    if(isComplete==false){
      isComplete=true;
      return;
    }
    
    super.turnOff();
        
    if(bText=="SCAN"){
      scan();
      return;
    } // SCAN
    
    if(bText==">" && aPort.portList!=null && aPort.portList.length>0){
      aPort.displayedPort=(aPort.displayedPort+1)%aPort.portList.length;
      portBox.setMessage(aPort.portList[aPort.displayedPort],aPort.portList[aPort.displayedPort].equals(arduinoPortXML.getContent())?color(50,150,50):color(50,50,200));
      portNumBox.setMessage("Port "+(aPort.displayedPort+1)+" of "+aPort.portList.length,color(50,50,50));
      return;
    } // >
     
    if(bText=="<" && aPort.portList!=null && aPort.portList.length>0){
      if(--aPort.displayedPort<0)
        aPort.displayedPort=aPort.portList.length-1;
      portBox.setMessage(aPort.portList[aPort.displayedPort],aPort.portList[aPort.displayedPort].equals(arduinoPortXML.getContent())?color(50,150,50):color(50,50,200));
      portNumBox.setMessage("Port "+(aPort.displayedPort+1)+" of "+aPort.portList.length,color(50,50,50));
      return;
    } // <
    
    if(bText=="CONNECT" && aPort.portList!=null && aPort.portList.length>0){
      arduinoPortXML.setContent(aPort.portList[aPort.displayedPort]);
      portBox.setMessage(aPort.portList[aPort.displayedPort],aPort.portList[aPort.displayedPort].equals(arduinoPortXML.getContent())?color(50,150,50):color(50,50,200));
      saveXML(dccStatusXML,STATUS_FILE);
      baseID=null;
      aPort.open(arduinoPortXML.getContent());
      return;
    } // <

  } // pressed

} // PortScanButton Class

//////////////////////////////////////////////////////////////////////////
//  ArduinoPort
//////////////////////////////////////////////////////////////////////////

class ArduinoPort{
  Serial port;
  Client client;
  String[] portList;
  int displayedPort;
  boolean emulate;
  String portName;
  int baud;
  
  ArduinoPort(){
    emulate=false;
    port=null;
    client=null;
  }

//////////////////////////////////////////////////////////////////////////
  
  void write(String text){
    msgBoxDiagOut.setMessage(text,color(30,30,150));

    if(emulate)
      simulate(text);
    else if(port!=null)
      port.write(text);
    else if(client!=null)
      client.write(text);
      
  } // write

//////////////////////////////////////////////////////////////////////////
  
  void simulate(String text){
    String c = text.substring(2,text.length()-1);

    switch(text.charAt(1)){
      
      case 'c':
        if(powerButton.isOn)
          receivedString("<a150>");
        else
          receivedString("<a10>");
        break;
        
      case '0':
        receivedString("<p0>");
        break;

      case '1':
        receivedString("<p1>");
        break;
        
      case 't':
        String[] s = splitTokens(c);
        if(int(s[2])==-1)
          s[2]="0";
        receivedString("<T"+s[0]+" "+s[2]+" "+s[3]+">");
        break;

      case 'T':
        String[] s1 = splitTokens(c);
        receivedString("<H"+s1[0]+" "+s1[1]+">");
        break;

      case 'z':
        String[] s2 = splitTokens(c);
        receivedString("<Z"+s2[0]+" "+s2[1]+">");
        break;
              
    } //switch
    
  } // simulate

//////////////////////////////////////////////////////////////////////////

  void open(String portName){
    int t;
    this.portName=portName;

    emulate=false;
    
    if(port!=null)
      port.stop();
      
    if(client!=null)
      client.stop();

    int[] n=int(splitTokens(portName,"."));

    if(n.length==4 && n[0]>0 && n[0]<=255 && n[1]>=0 && n[1]<=255 && n[2]>=0 && n[2]<=255 && n[3]>=0 && n[3]<=255){
      client=new Client(Applet,portName,2560);
      if(client.ip()==null){
        msgBoxMain.setMessage("Can't connect to Server: "+portName,color(200,50,0));
        client=null;
        return;
      } else if(client!=null){
        msgBoxMain.setMessage("Waiting for Base Station at Server: "+client.ip(),color(200,50,0));
        client.write("<s>");
        return;
      }
    }
    
    if(portName.equals("Emulator")){
      emulate=true;
      msgBoxMain.setMessage("Using Emulator to Simulate Arduino",color(50,50,200));
      return;
    }
        
    try{
      port=new Serial(Applet,portName,BASE_BAUD);
      port.bufferUntil('>');
    } catch(Exception e){
      msgBoxMain.setMessage("Serial Port Busy: "+portName,color(200,50,0));
      port=null;
      return;
    }

    if(port.port==null){
      msgBoxMain.setMessage("Can't find Serial Port: "+portName,color(200,50,0));
      port=null;
      return;
    }

    msgBoxMain.setMessage("Waiting for Base Station at Serial Port: "+portName,color(200,50,0));

    t=millis();
    while(millis()-t<3000);    
    port.write("<s>");
              
  } // open()

} // Class ArduinoPort

//////////////////////////////////////////////////////////////////////////