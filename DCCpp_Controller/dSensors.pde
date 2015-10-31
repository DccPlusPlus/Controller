//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Classes for Sensors and AutoPilot Control
//
//  AutoPilot Button - automaticaly operates three cabs in a pattern
//                     by which each cab travels out to the sky bridge,
//                     reverses course, and comes back into the inner
//                     reversing loop after passing through the crossover
//                   - status is saved between session
//                   - clicking this button RESUMES a previous session
//                     or stops the current session
//                   - resumption implies all cabs, turnouts, and sensors are in
//                     the exact same position as before the session was halted
//                   - shift-clicking this button STARTS a new session
//                   - starting a new seesion assume all cabs are in their start position
//                     but sensors and turnouts will be automatically reset
//
//  TrackSensor     - defines a track sensor that triggers when the first car of a train passes, and
//                    then again when the last car of that same train passes.
//                  - creates a track sensor button on the track layout where ther sensor is located
//                  - a given track sensor is defined to be "on" once an initial trigger is received from passage
//                    of first the car of a train, and defined to be "off" once a second trigger is received from
//                    passage of last car of that same train
//                  - if the on/off status of a track sensor button seems out of sync with the actual train,
//                    user can manually toggle the sensor "on" or "off" by clicking the appropriate sensor button
//                  
//////////////////////////////////////////////////////////////////////////

class AutoPilotButton extends RectButton{
  int[] cabs={8601,6021,1506,622,1202,54};                              // list of all cabs to be included in autoPilot - order does not matter since it will be randomized
  ArrayList<CabButton> cabList = new ArrayList<CabButton>();
  int phase=0;
  int tCount=0;
  int crossOver=0;
  AutoProgram program=AutoProgram.NONE;
  XML cabListXML, phaseXML, tCountXML, crossOverXML, programXML;
  int safetyTimer;

  AutoPilotButton(int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    this(null, xPos, yPos, bWidth, bHeight, baseHue, fontSize, bText);
  }
  
  AutoPilotButton(Window window, int xPos, int yPos, int bWidth, int bHeight, int baseHue, int fontSize, String bText){
    super(window, xPos, yPos, bWidth, bHeight, baseHue, color(0), fontSize, bText, ButtonType.NORMAL);
    
    phaseXML=autoPilotXML.getChild("Phase");
    if(phaseXML==null){
      phaseXML=autoPilotXML.addChild("Phase");
      phaseXML.setContent(str(phase));
    } else{
      phase=int(phaseXML.getContent());
    }
    
    tCountXML=autoPilotXML.getChild("TCount");
    if(tCountXML==null){
      tCountXML=autoPilotXML.addChild("TCount");
      tCountXML.setContent(str(tCount));
    } else{
      tCount=int(tCountXML.getContent());
    }

    crossOverXML=autoPilotXML.getChild("CrossOver");
    if(crossOverXML==null){
      crossOverXML=autoPilotXML.addChild("CrossOver");
      crossOverXML.setContent(str(crossOver));
    } else{
      crossOver=int(crossOverXML.getContent());
    }
    
    programXML=autoPilotXML.getChild("Program");
    if(programXML==null){
      programXML=autoPilotXML.addChild("Program");
      programXML.setContent(program.name);
    } else{
      program=AutoProgram.index(programXML.getContent());
    }
    
    cabListXML=autoPilotXML.getChild("CabList");
    if(cabListXML==null){
      cabListXML=autoPilotXML.addChild("CabList");
      cabListXML.setContent(join(nf(cabs,0)," "));
    }
    
    for(int i: int(split(trim(cabListXML.getContent())," ")))
      cabList.add(cabsHM.get("Cab"+i));
      
    updateDiagBox();
        
  } // AutoButton
  
//////////////////////////////////////////////////////////////////////////

  void display(){
    super.display();

    textAlign(CENTER,CENTER);
    textFont(messageFont,12);
    fill(color(255));
    text(program.name,xPos+xWindow(),yPos+yWindow()+bHeight/2+10);
        
  }
  
//////////////////////////////////////////////////////////////////////////

  void pressed(){
                    
    if(isOn){
      turnOff();
      return;
    }
    
    if(program==AutoProgram.NONE){
      msgBoxMain.setMessage("Can't resume Auto Pilot until program specified!",color(50,50,200));
      return;
    }
    
    for(CabButton cb : cabList)                    // set throttles of all cabs specified in current program to prior values
      cb.setThrottle(ThrottleSpeed.index(cb.speedXML.getContent()));
      
    if(program.equals(AutoProgram.AUTO_CLEAN))
      cleaningCab.turnOn();
        
    msgBoxMain.setMessage("Auto Pilot Resuming",color(50,50,200));
    safetyTimer=millis();    
    turnOn();
  } // pressed
  
//////////////////////////////////////////////////////////////////////////

  void init(){
    phase=0;
    tCount=0;
    crossOver=0;
            
    for(TrackSensor ts : sensorsHM.values())
      ts.reset();

    cabList.clear();
    for(int i:cabs)
      cabList.add(cabsHM.get("Cab"+i));
          
    for(int i=0;i<3;i++)      // randomize list
      cabList.add(0,cabList.remove(int(random(i,cabList.size()))));

    updateCabList();
     
    for(CabButton cb : cabList)            // halt all cabs specified in full autopilot program
      cb.setThrottle(ThrottleSpeed.STOP);            

    rButtonReset.pressed();
    cabList.get(0).sidingRoute.pressed();  // set siding turnouts so they are aligned for first cab
    rButtonSpiral.pressed();
    rButton12.pressed();
    
    cabList.get(0).setThrottle(ThrottleSpeed.FULL);  // start first cab!
          
    msgBoxMain.setMessage("Auto Pilot Engaged",color(50,50,200));
    updateDiagBox();    
        
  } // init()

  
//////////////////////////////////////////////////////////////////////////

  void clean(){

    if(isOn){
      msgBoxMain.setMessage("Auto Pilot already engaged!",color(50,50,200));
      return;
    }
    
    cleaningCab.turnOn();                                  // turn on cleaning car
    cabList.clear();
    cabList.add(cabsHM.get("Cab"+2004));                   // assumes cab 2004 is pulling cleaning car
    updateCabList();
    phase=100;
    phaseXML.setContent(str(phase));   
    tButton10.pressed(0);
    
    for(TrackSensor ts : sensorsHM.values())
      ts.reset();    
      
    cabList.get(0).setThrottle(ThrottleSpeed.FULL);        // start throttle for cab
    msgBoxMain.setMessage("Auto Clean Engaged",color(50,50,200));
    setProgram(AutoProgram.AUTO_CLEAN);
    safetyTimer=millis();        
    turnOn();

  } // clean 

//////////////////////////////////////////////////////////////////////////

  void parkCab(CabButton selectedCab){
    
    if(selectedCab.parkingSensor==0){
      msgBoxMain.setMessage("Auto Park not available for Cab "+selectedCab.cab,color(50,50,200));
      return;
    }    
  
    if(isOn){
      msgBoxMain.setMessage("Auto Pilot already engaged!",color(50,50,200));
      return;
    }
    
    cabList.clear();
    cabList.add(selectedCab);
    updateCabList();
    phase=42;
    phaseXML.setContent(str(phase));    
    cabList.get(0).setThrottle(ThrottleSpeed.FULL);        // start throttle for cab selected --- do not modify throttles for any other cabs
    msgBoxMain.setMessage("Auto Park Engaged for Cab "+selectedCab.cab,color(50,50,200));
    setProgram(AutoProgram.SINGLE_CAB_PARK);
    safetyTimer=millis();        
    turnOn();

  } // parkCab
  
//////////////////////////////////////////////////////////////////////////

  void shiftPressed(){
            
    if(!isOn){
      setProgram(AutoProgram.ALL_CABS_RUN);
      safetyTimer=millis();        
      turnOn();
      msgBoxMain.setMessage("Starting Auto Pilot...",color(50,50,200));      
      buttonQueue.add(this);
    } else
    if(program==AutoProgram.ALL_CABS_RUN){
      msgBoxMain.setMessage("Switching to Auto Park",color(50,50,200));      
      setProgram(AutoProgram.ALL_CABS_PARK);
    } else{
      msgBoxMain.setMessage("Auto Park or other program already engaged!",color(50,50,200));      
    }
  } // shiftPressed
  
//////////////////////////////////////////////////////////////////////////

  void turnOff(){
    super.turnOff();
    
    msgBoxMain.setMessage("Auto Pilot Disengaged",color(50,50,200));

    for(CabButton cb : cabList)            // halt (but without updating XML) all cabs specified in current program only
      cb.stopThrottle();

    if(program.equals(AutoProgram.AUTO_CLEAN))
      cleaningCab.turnOff();    
      
    if(program.equals(AutoProgram.SINGLE_CAB_RUN)){
      aPort.write("<u>");
      setProgram(AutoProgram.NONE);
    }
  }

//////////////////////////////////////////////////////////////////////////

 void updateCabList(){

    cabListXML.setContent("");
    for(CabButton cb : cabList)
      cabListXML.setContent(cabListXML.getContent()+cb.cab+" ");
      
    cabListXML.setContent(trim(cabListXML.getContent()));
 }
 
//////////////////////////////////////////////////////////////////////////

  void process(int s, boolean isActive){
    
    int lastPhase;

    if(!isOn || program.equals(AutoProgram.SINGLE_CAB_RUN))
      return;
      
    if(!isActive)
      s=-s;
      
    lastPhase=phase;
              
    switch(s){
      
      case 1:
        if(phase==3){
          rButtonBridge.pressed();
          phase=4;
        } else
        if(phase==4){
          phase=5;
        } else
        if(phase==5){
          phase=6;
        } else
        if(phase==10){
          crossOver++;
          if(crossOver==2){
            cabList.get(0).stopThrottle();
//            cabList.get(0).activateFunction(CabFunction.HORN,true);
//            cabList.get(0).activateFunction(CabFunction.HORN,false);
          } else{
            cabList.get(0).activateFunction(CabFunction.S_HORN,true);
          }
        } else
        if(phase==11){
          phase=12;
        } else
        if(phase==13){
          phase=14;
        } else
        if(phase==40){
          tButton20.pressed(0);
          phase=41;
        }
        break;
      
      case -1:
        if(phase==2){
          tCount++;
        } else
        if(phase==120){
          phase=42;
          tButton20.pressed(1);
          tButton10.pressed(0);
        }
        break;

      case 2:
        if(phase==0){
         tButton40.routeDisabled();
         cabList.get(1).sidingRoute.pressed();
         tButton40.routeEnabled();
         cabList.get(1).setThrottle(ThrottleSpeed.FULL);
         phase=1;
//        } else
//        if(phase==10 || phase==11){
//          cabList.get(2).setFunction(CabFunction.HORN,false);
        } else
        if(phase==30){
          tButton50.pressed(1);
          phase=31;
        }
        break;
        
      case -2:
        if(phase==2){
          tCount++;
          if(tCount==1)
            cabList.get(1).setThrottle(ThrottleSpeed.STOP);
        } else
        if(phase==9){
          tButton30.pressed(1);
          tCount++;
        } else
        if(phase==10){
          if(crossOver>0){
            crossOver--;
          }
          if(crossOver==1){
            cabList.get(0).setThrottle(ThrottleSpeed.FULL);
//            cabList.get(0).activateFunction(CabFunction.S_HORN,true);
          }
        }        
        break;
        
      case 3:
        if(phase==7){
          tButton30.pressed(0);
          phase=8;
        } else
        if(phase==10){
          crossOver++;
          if(crossOver==2){
            cabList.get(2).stopThrottle();
//            cabList.get(2).activateFunction(CabFunction.HORN,true);
//            cabList.get(2).activateFunction(CabFunction.HORN,false);
          } else{
            cabList.get(2).activateFunction(CabFunction.S_HORN,true);
          }
        }
        break;
        
      case -3:
        if(phase==110){
          phase++;
          tButton30.pressed(1);
        } else
        if(phase==111||phase==112){
          phase++;
        } else
        if(phase==113){
          phase++;
          tButton30.pressed(0);
          tButton40.pressed(1);
          tButton1.pressed(0);
        }
        break;

      case 4:
        if(phase==1){
          tButton40.routeDisabled();
          cabList.get(2).sidingRoute.pressed();
          tButton40.routeEnabled();
          cabList.get(2).setThrottle(ThrottleSpeed.FULL);
          phase=2;
        } else
        if(phase==8){
          tButton40.pressed(0);
          phase=9;
//        } else
//        if(phase==10){
//          cabList.get(0).setFunction(CabFunction.HORN,false);
        } else
        if(phase==12){
          tButton4.pressed(1); // set reversing loop
          tButton7.pressed(0);
          phase=20;            // start "parking" phase, then resume pattern
        } else
        if((phase==21 || phase==31 || phase==42) && cabList.get(0).parkingSensor==4){
          cabList.get(0).setThrottle(ThrottleSpeed.SLOW);
          phase++;
        } else
        if(phase==41){
          tButton50.pressed(0);
          tButton4.pressed(1); // set reversing loop
          tButton7.pressed(0);
          phase=42;
        }
        break;
        
      case -4:
        if(phase==10){
          if(crossOver>0){
            crossOver--;
          }
          if(crossOver==1){
            cabList.get(2).setThrottle(ThrottleSpeed.FULL);
//            cabList.get(2).activateFunction(CabFunction.S_HORN,true);
          }
          cabList.get(1).setThrottle(ThrottleSpeed.FULL); // just in case cab-1 was stopped on bridge
          tButton40.pressed(1);
          tButton1.pressed(0);
          tButton20.pressed(1);
          crossOver=0;
          phase=11;
        } else
        if((phase==22 || phase==32 || phase==43) && cabList.get(0).parkingSensor==4){
          phase++;
          cabList.get(0).setThrottle(ThrottleSpeed.STOP);
          cabList.get(0).sidingRoute.shiftPressed();
          delay(500);
          cabList.get(0).sidingRoute.pressed();
          sensorsHM.get(cabList.get(0).sidingSensor).pressed(false);
          cabList.get(0).setThrottle(ThrottleSpeed.REVERSE);
        }      
        break;

      case 5:
        if(phase==6){
         cabList.get(0).setThrottle(ThrottleSpeed.SLOW);
        } else
        if(phase==14){
         cabList.get(1).setThrottle(ThrottleSpeed.SLOW);
        } else
        if(phase==42 && cabList.get(0).parkingSensor==5){
          cabList.get(0).setThrottle(ThrottleSpeed.SLOW);
          phase++;
        }        
        break;
        
      case -5:
        if(phase==6){
          cabList.get(0).setThrottle(ThrottleSpeed.STOP);
          phase=7;
        } else
        if(phase==14){
          cabList.get(1).setThrottle(ThrottleSpeed.STOP);
          cabList.add(cabList.remove(0));        // move cab-0 to end of list
          updateCabList();
          phase=7;        // start next cycle
        } else
        if(phase==43 && cabList.get(0).parkingSensor==5){
          phase++;
          cabList.get(0).setThrottle(ThrottleSpeed.STOP);
          cabList.get(0).sidingRoute.shiftPressed();
          delay(500);
          cabList.get(0).sidingRoute.pressed();
          sensorsHM.get(cabList.get(0).sidingSensor).pressed(false);
          delay(100);
          cabList.get(0).setThrottle(ThrottleSpeed.REVERSE);
        } else
        if(phase==100){
          phase++;
          tButton10.pressed(1);        
          tButton30.pressed(1);
          tButton50.pressed(1);
          tButton4.pressed(0);
          tButton20.pressed(0);
        } else
        if(phase==101||phase==102){
          phase++;
        } else
        if(phase==103){
          phase++;
          tButton20.pressed(1);
          tButton50.pressed(0);
        } else
        if(phase==104||phase==105){
          phase++;
        } else
        if(phase==106){
          phase++;
          tButton10.pressed(0);
        } else
        if(phase==107||phase==108){
          phase++;
        } else
        if(phase==109){
          phase++;
          tButton20.pressed(0);
          tButton30.pressed(0);
        }
        break;
        
      case 6:
        if(phase==10){
         cabList.get(1).stopThrottle(); // wait on bridge until cab-0 clears sensor 4
        }
        break;
        
      case -6:
        if(phase==9){
          tCount++;
          tButton8.pressed();
        }
        break;
        
      case 7:
      case 8:
      case 9:
      case 10:
      case 12:
      case 13:
      case 14:
        if(phase==23 || phase==33 || phase==44){
          phase++;
          cabList.get(0).setThrottle(ThrottleSpeed.REVERSE_SLOW);
        }
        break;
        
      case -7:
      case -8:
      case -9:
      case -10:
      case -12:
      case -13:
      case -14:
        if(phase==24 || phase==34 || phase==45){
          cabList.get(0).setThrottle(ThrottleSpeed.STOP);
          sensorsHM.get(cabList.get(0).parkingSensor).pressed(false);
          tButton40.pressed(1);
          if(program==AutoProgram.SINGLE_CAB_PARK||program==AutoProgram.AUTO_CLEAN){
            phase=51;                                // phase must have previously been 45
            turnOff();
          } else
          if(program==AutoProgram.ALL_CABS_PARK){
            cabList.add(0,cabList.remove(2));        // move cab-2 to beginning of list, making it cab-0
            updateCabList();
            phase+=6;                                // start parking routine at either phase=30, or if second cab just parked then phase=40, or if third cab finished parking phase=51
            if(phase==51){
              turnOff();
            }
          } else{
            cabList.add(3,cabList.remove(int(random(3,cabList.size()))));      // pick random cab to be next to leave siding
            updateCabList();
            tButton40.routeDisabled();
            cabList.get(3).sidingRoute.pressed();
            tButton40.routeEnabled();
            cabList.get(3).setThrottle(ThrottleSpeed.FULL);
            phase=25;
          }          
        }      
        break;
                
      case 11:
        if(phase==20){
          phase=21;
        } else
        if((phase==21 || phase==31 || phase==42) && cabList.get(0).parkingSensor==11){
          cabList.get(0).setThrottle(ThrottleSpeed.SLOW);
          phase++;
        } else
        if(phase==25){
          phase=26;
        } else
        if(phase==26){
          phase=13;
        }
        break;
        
      case -11:
        if((phase==22 || phase==32 || phase==43) && cabList.get(0).parkingSensor==11){
          phase++;
          cabList.get(0).setThrottle(ThrottleSpeed.STOP);
          cabList.get(0).sidingRoute.shiftPressed();
          delay(500);
          cabList.get(0).sidingRoute.pressed();
          sensorsHM.get(cabList.get(0).sidingSensor).pressed(false);
          delay(100);
          cabList.get(0).setThrottle(ThrottleSpeed.REVERSE);
        } else
        if(phase==114||phase==115){
          phase++;
        } else
        if(phase==116){
          phase++;
          tButton4.pressed(1);
          tButton7.pressed(0);
          tButton5.pressed(0);
          tButton20.pressed(0);
          tButton8.pressed(0);
        } else 
        if(phase==117){
          phase++;
          tButton40.pressed(0);
        } else
        if(phase==118||phase==119){
          phase++;
        }
        break;
        
    } // switch t
    
    if(phase==2 && tCount==2){
      cabList.get(1).setThrottle(ThrottleSpeed.FULL);  // just in case cab-1 was previously stopped to wait for cab-0 to catch up
      rButton10.pressed();
      rButton11.pressed();
      tCount=0;
      phase=3;
    } else
    
    if(phase==9 && tCount==2){
      cabList.get(0).setThrottle(ThrottleSpeed.FULL);
      tButton20.pressed(0);
      tButton4.pressed(0);
      tCount=0;
      crossOver=0;
      phase=10;
    }

    phaseXML.setContent(str(phase));
    tCountXML.setContent(str(tCount));
    crossOverXML.setContent(str(crossOver));
    
    updateDiagBox();
    
    if(phase!=lastPhase)    // there was an update of the phase
      safetyTimer=millis();  // reset timer
    

  } // process

//////////////////////////////////////////////////////////////////////////

  void setProgram(AutoProgram p){
    program=p;
    programXML.setContent(program.name);
    updateDiagBox();
    saveXMLFlag=true;
  }
  
//////////////////////////////////////////////////////////////////////////
  void updateDiagBox(){
  
    String s="";    
      
     for(XML xml: autoPilotXML.getChildren()){
       if(!xml.getName().equals("#text"))
         s=s+(String.format("%10s",xml.getName())+" = "+xml.getContent()+"\n");
     }
     
     msgAutoState.setMessage(s);
   
 }  // updateDiagBox

//////////////////////////////////////////////////////////////////////////

  void safetyCheck(){
    
    int countDown;
    
    if(!isOn || program.equals(AutoProgram.SINGLE_CAB_RUN))
      return;
    
    countDown=120-int((millis()-safetyTimer)/1000);
    
    msgAutoTimer.setMessage("Timer = "+countDown);
    
    if(countDown<=0){
      powerButton.turnOff();
      turnOff();
    }
    
  } // safetyCheck
  
} // AutoPilot Class

//////////////////////////////////////////////////////////////////////////
//  DCC Component: TrackSensor
//////////////////////////////////////////////////////////////////////////

class TrackSensor extends Track{
  boolean isActive=false;
  boolean sensorDefault;
  int xPos, yPos;
  int mTime;
  int kWidth, kHeight;
  String sensorName;
  int sensorNum;
  XML sensorButtonXML;
  MessageBox msgBoxSensor;

  TrackSensor(Track refTrack, int trackPoint, float tLength, int kWidth, int kHeight, int sensorNum, boolean sensorDefault){
    super(refTrack,trackPoint,tLength);
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.xPos=int(x[1]*layout.sFactor+layout.xCorner);
    this.yPos=int(y[1]*layout.sFactor+layout.yCorner);   
    this.sensorNum=sensorNum;
    sensorName="Sensor"+sensorNum;
    componentName=sensorName;
    this.sensorDefault=sensorDefault;
    sensorButtonXML=sensorButtonsXML.getChild(sensorName);
    if(sensorButtonXML==null){
      sensorButtonXML=sensorButtonsXML.addChild(sensorName);
      sensorButtonXML.setContent(str(isActive));
    } else{
      isActive=boolean(sensorButtonXML.getContent());
    }
  sensorsHM.put(sensorNum,this);
  msgBoxSensor=new MessageBox(sensorWindow,0,sensorNum*22+22,-1,0,color(175),18,"S-"+nf(sensorNum,2)+":",color(50,50,250));  
  }

  TrackSensor(Track refTrack, int trackPoint, float curveRadius, float curveAngleDeg, int kWidth, int kHeight, int sensorNum, boolean sensorDefault){
    super(refTrack,trackPoint,curveRadius,curveAngleDeg);
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.xPos=int(x[1]*layout.sFactor+layout.xCorner);
    this.yPos=int(y[1]*layout.sFactor+layout.yCorner);    
    this.sensorNum=sensorNum;
    this.sensorDefault=sensorDefault;
    sensorName="Sensor"+sensorNum;
    componentName=sensorName;
    sensorButtonXML=sensorButtonsXML.getChild(sensorName);
    if(sensorButtonXML==null){
      sensorButtonXML=sensorButtonsXML.addChild(sensorName);
      sensorButtonXML.setContent(str(isActive));
    } else{
      isActive=boolean(sensorButtonXML.getContent());
    }
  sensorsHM.put(sensorNum,this);
  msgBoxSensor=new MessageBox(sensorWindow,0,sensorNum*22+22,-1,0,color(175),18,"S-"+nf(sensorNum,2)+":",color(50,50,250));
  }
  
//////////////////////////////////////////////////////////////////////////

  void display(){
    ellipseMode(CENTER);

    strokeWeight(1);
    stroke(color(255,255,0));
    noFill();
    
    if(isActive)
      fill(color(50,50,200));
    
    ellipse(xPos,yPos,kWidth/2,kHeight/2);
  } // display()  
  
//////////////////////////////////////////////////////////////////////////

  void pressed(){
    pressed(!isActive);
  }
  
//////////////////////////////////////////////////////////////////////////

  void pressed(boolean isActive){
    this.isActive=isActive;    
    autoPilot.process(sensorNum,isActive);
    sensorButtonXML.setContent(str(isActive));
    saveXMLFlag=true;
    if(isActive){
      msgBoxSensor.setMessage("S-"+nf(sensorNum,2)+": "+nf(hour(),2)+":"+nf(minute(),2)+":"+nf(second(),2)+" - "+nf((millis()-mTime)/1000.0,0,1)+" sec");
      mTime=millis();
    }
            
  } // pressed

//////////////////////////////////////////////////////////////////////////

  void reset(){
    pressed(sensorDefault);
            
  } // reset

//////////////////////////////////////////////////////////////////////////

  void check(){
    if(selectedComponent==null && (mouseX-xPos)*(mouseX-xPos)/(kWidth*kWidth/4.0)+(mouseY-yPos)*(mouseY-yPos)/(kHeight*kHeight/4.0)<=1){
      cursorType=HAND;
      selectedComponent=this;
    }
    
  } // check

} // TrackSensor Class