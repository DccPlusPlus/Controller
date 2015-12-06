//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Event Handlers
//
//  Top-level processing of mouse, keyboard, and serial events.
//  Most of the real functionality is contained in other methods,
//  functions, and classes called by these handlers
//
//////////////////////////////////////////////////////////////////////////

void mouseDragged(){
  if(selectedComponent!=null)
    selectedComponent.drag();
}

//////////////////////////////////////////////////////////////////////////

void mousePressed(){
      
  if(activeInputBox!=null){
    for(InputBox inputBox : activeInputBox.linkedBoxes)
      inputBox.setIntValue(activeInputBox.getIntValue());
  }
  
  activeInputBox=null;
  if(selectedComponent!=null){
    if (keyPressed == true && key == CODED){
      if(keyCode == SHIFT){
        selectedComponent.shiftPressed();
      } else if(keyCode == CONTROL){
          msgBoxMain.setMessage("Component Name: "+selectedComponent.componentName,color(30,30,150));
      }
    }
    else if(mouseButton==LEFT){
      selectedComponent.pressed();
    } else {
      selectedComponent.rightClick();
    }
  }
    
}

//////////////////////////////////////////////////////////////////////////

void mouseReleased(){
  if(selectedComponent!=null)
    selectedComponent.released();
}

//////////////////////////////////////////////////////////////////////////

void keyPressed(){
  keyCommand(key, keyCode);
}
   
//////////////////////////////////////////////////////////////////////////

void keyReleased(){
  keyCommandReleased(key, keyCode);
}
   
//////////////////////////////////////////////////////////////////////////
    
void serialEvent(Serial p){
  receivedString(p.readString());
}
 
//////////////////////////////////////////////////////////////////////////

void clientEvent(Client c){
  String s;
  s=c.readStringUntil('>');
  if(s!=null)
    receivedString(s);
}

//////////////////////////////////////////////////////////////////////////

  void receivedString(String s){   
    if(s.charAt(0)!='<')
      return;

    String c=s.substring(2,s.length()-1);
  
    switch(s.charAt(1)){

      case 'i':
        baseID=c;
        msgBoxMain.setMessage("Found "+baseID,color(0,150,0));
        break;
        
      case '*':
        msgBoxDiagIn.setMessage(c,color(30,30,150));
      break;
        
      case 'r':
        String[] cs=splitTokens(c,"|");
        callBacks.get(int(cs[0])).execute(int(cs[1]),cs[2]);
      break;

      case 'T':
        int[] n=int(splitTokens(c));
        if(n[0]>cabButtons.size())
          break;
        CabButton t=cabButtons.get(n[0]-1);
        if(n[2]==1)
          t.speed=n[1];
        else
          t.speed=-n[1];
        break;

      case 'Q':
        if(sensorsHM.get(int(c))!=null){
          sensorsHM.get(int(c)).pressed();
        }
        break;
        
      case 'Y':
        int[] h1=int(splitTokens(c));
        if(remoteButtonsHM.get(h1[0])!=null){
          if(h1[1]==1)
            remoteButtonsHM.get(h1[0]).turnOn();
          else
            remoteButtonsHM.get(h1[0]).turnOff();
        }
        break;

      case 'H':
        int[] h=int(splitTokens(c));
                
        if(trackButtonsHM.get(h[0])!=null){
          trackButtonsHM.get(h[0]).update(h[1]);
        } else if(remoteButtonsHM.get(h[0])!=null){
          if(h[1]==1)
            remoteButtonsHM.get(h[0]).turnOn();
          else
            remoteButtonsHM.get(h[0]).turnOff();
        }
        
        break;
        
      case 'L':
        int[] z=int(splitTokens(c));
        color tempColor;
        tempColor=color(z[0],z[1],z[2]);
        colorMode(HSB,1.0,1.0,1.0);
        ledColorButton.hue=hue(tempColor);
        ledColorButton.sat=saturation(tempColor);
        ledColorButton.val=brightness(tempColor);
        ledColorButton.update(0);
        colorMode(RGB,255);        
        break;
        
      case 'U':
        autoPilot.cabList.clear();        
        autoPilot.setProgram(AutoProgram.SINGLE_CAB_RUN);
        autoPilot.turnOn();
        break;
        
      case 'p':
        if(c.equals("1")){
          powerButton.isOn=true;
          msgBoxMain.setMessage("Track Power On",color(30,30,150));
        } else if(c.equals("0")){
          powerButton.isOn=false;
          msgBoxMain.setMessage("Track Power Off",color(30,30,150));
        } else if(c.equals("2")){
          msgBoxMain.setMessage("MAIN Track Current Overload - Power Off",color(200,30,30));
          powerButton.isOn=false;
        } else if(c.equals("3")){
          msgBoxMain.setMessage("PROG Track Current Overload - Power Off",color(200,30,30));
          powerButton.isOn=false;
        }
        break;

      case 'a':
        currentMeter.addSample(int(c));
        break;

    }
  } // receivedString

//////////////////////////////////////////////////////////////////////////

  void keyCommand(char k, int kC){
    
    if(activeInputBox!=null){
      activeInputBox.keyStroke(k, kC);
      return;
    }
        
    if(k==CODED){
      switch(kC){
        case UP:
          if(throttleA.cabButton!=null){
            if(!keyHold)
              throttleA.pressed();
            throttleA.keyControl(1);
          }
          break;
        case DOWN:
          if(throttleA.cabButton!=null){
            if(!keyHold)
              throttleA.pressed();
            throttleA.keyControl(-1);
          }
          break;
        case LEFT:
          if(throttleA.cabButton!=null){
            throttleA.keyControl(0);
          }
          break;
        case RIGHT:
          if(throttleA.cabButton!=null){
            throttleA.cabButton.stopThrottle();
          }
          break;
      }
    } // key is coded
    
    else{
      switch(k){
        case 'P':
          powerButton.turnOn();
          break;
          
        case 'F':
          aPort.write("<3>");
          break;
          
        case 'f':
          aPort.write("<2>");
          break;

        case ' ':
          powerButton.turnOff();
          break;
          
        case 'a':
          accWindow.toggle();
          break;

        case 'c':
          currentMeter.isOn=!currentMeter.isOn;
          break;

        case 'e':
          extrasWindow.toggle();
          break;

        case 'x':
          autoWindow.toggle();
          break;

        case 'S':
          sensorWindow.toggle();
          break;

        case 'l':
          ledWindow.toggle();
          break;

        case 's':
          portWindow.toggle();          
          break;

        case 'h':
          helpWindow.toggle();          
          break;

        case 'q':
          imageWindow.toggle();          
          break;

        case 'd':
          diagWindow.toggle();          
          break;
          
        case 'i':
          if(layoutBridge.equals(layout2))
            layoutBridge.copy(layout);
          else
            layoutBridge.copy(layout2);
          break;
          
        case 'p':
          progWindow.toggle();
          break;
          
        case 'o':
          opWindow.toggle();
          break;
          
        case 'n':
          if(throttleA.cabButton!=null){
            throttleA.cabButton.fbWindow.close();
            throttleA.cabButton.fbWindow=throttleA.cabButton.windowList.get((throttleA.cabButton.windowList.indexOf(throttleA.cabButton.fbWindow)+1)%throttleA.cabButton.windowList.size());
            throttleA.cabButton.fbWindow.open();
          }
          break;
                    
        case '1':
        case '2':
        case '3':
        case '4':
        case '5':
        case '6':
        case '7':
          cabButtons.get(int(k)-int('1')).pressed();
          break;
          
      }
    } // key not coded
    
  keyHold=true;
  } // keyCommand

//////////////////////////////////////////////////////////////////////////

  void keyCommandReleased(char k, int kC){

    keyHold=false;
    
    if(k==CODED){
      switch(kC){
      }
    } // key is coded
    
    else{
      switch(k){          
      }
    } // key not coded

  } // keyCommandReleased


//////////////////////////////////////////////////////////////////////////