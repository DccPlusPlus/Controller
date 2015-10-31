//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Class for Track Button
//
//  TrackButton  -  creates a TURNOUT or CROSSOVER by grouping two sets of
//                  of pre-specified tracks
//               -  one set of tracks defines the state of the turnout
//                  or crossover in the "open" position
//               -  the other set of tracks defines the state of the turnout
//                  or crossover in the "closed" position
//               -  a clickable but otherwise invisible button (the Track Button)
//                  located near the center of the turnout or crossover
//                  toggles between the closed and open positions
//
//
//               -  when toggled, TrackButton will:
//  
//                    * reset the colors of each set of tracks to
//                      indicate whether the turnour or crossover
//                      is "open" or "closed"
//
//                    * reset the color of any route buttons that use this
//                      track button
//
//                    * send a DCC ACCESSORY COMMAND to the DCC++ Base Station
//                      using the Accessory Address and Accessory Number
//                      specified for this Track Button
//
//                      In accordance with NMRA DCC Standards, accessory decoders
//                      are controlled using 12 bits messages.  The first 11 form
//                      a main address (9 bits) and a sub address (2 bits).  Depending
//                      on the specifics of a particular manufacturers decoder, these
//                      11 bits can be interpreted as a single address (0-2047) or
//                      as a main address (0-511) with 4 sub addresses (0-3).  Some decoders
//                      may respond to any address matching the first 9 bits; others may
//                      also consider the two sub address bits. In any case, Track Button
//                      can be used to send the correct combination of 11 bits to sucessfully
//                      communicate with the decoder.
//
//                      The 12th bit is generally considered to be the data bit that is used
//                      to toggle the accessory either on or off.  In the case of a decoder
//                      driving a turnout or crossover, this data bit is used to toggle between
//                      the open and closed positions.
//
//////////////////////////////////////////////////////////////////////////

class TrackButton extends DccComponent{
  int xPos, yPos;
  int kWidth, kHeight;
  int buttonStatus=0;
  int id;
  boolean rEnabled=true;
  ArrayList<Track> aTracks = new ArrayList<Track>();
  ArrayList<Track> bTracks = new ArrayList<Track>();
  ArrayList<RouteButton> aRouteButtons = new ArrayList<RouteButton>();
  ArrayList<RouteButton> bRouteButtons = new ArrayList<RouteButton>();
  
  TrackButton(int kWidth, int kHeight, int id){
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.id=id;
    this.componentName="T"+id;    
    trackButtonsHM.put(id,this);
    dccComponents.add(this);
  } // FunctionButton

//////////////////////////////////////////////////////////////////////////

  void addTrack(Track track, int tPos){
    int n=aTracks.size()+bTracks.size();
    this.xPos=int((this.xPos*n+(track.x[0]+track.x[1])/2.0*track.layout.sFactor+track.layout.xCorner)/(n+1.0));
    this.yPos=int((this.yPos*n+(track.y[0]+track.y[1])/2.0*track.layout.sFactor+track.layout.yCorner)/(n+1.0));
    
    if(tPos==0){                       // specifies that this track should be considered part of aTracks
      track.tStatus=1-buttonStatus;
      aTracks.add(track);
    } else if (tPos==1) {             // specifies that this track should be considered part of bTracks
      track.tStatus=buttonStatus;
      bTracks.add(track);
    }

  }
  
//////////////////////////////////////////////////////////////////////////
  
  void display(){    
    if(buttonStatus==0){
      for(Track track : bTracks)
        track.display();
      for(Track track : aTracks)
        track.display();
    } else {
      for(Track track : aTracks)
        track.display();
      for(Track track : bTracks)
        track.display();
    }
  } // display
  
//////////////////////////////////////////////////////////////////////////

  void check(){
    if(selectedComponent==null && (mouseX-xPos)*(mouseX-xPos)/(kWidth*kWidth/4.0)+(mouseY-yPos)*(mouseY-yPos)/(kHeight*kHeight/4.0)<=1){
      cursorType=HAND;
      selectedComponent=this;
    }    
  } // check
  
//////////////////////////////////////////////////////////////////////////

  void routeEnabled(){
    rEnabled=true;
  }
//////////////////////////////////////////////////////////////////////////

  void routeDisabled(){
    rEnabled=false;
  }

//////////////////////////////////////////////////////////////////////////

  void pressed(){
    pressed(1-buttonStatus);
  }
  
//////////////////////////////////////////////////////////////////////////

  void pressed(int buttonStatus){
     aPort.write("<T"+id+" "+buttonStatus+">");
     delay(50);
  }

//////////////////////////////////////////////////////////////////////////
  
  void update(int buttonStatus){
  
    this.buttonStatus=buttonStatus;
    
    for(Track track : aTracks)
      track.tStatus=1-buttonStatus;
    for(Track track : bTracks)
      track.tStatus=buttonStatus;
    
    if(buttonStatus==0){  
      for(RouteButton routeButton : bRouteButtons)
        routeButton.routeOn=false;
    } else {
      for(RouteButton routeButton : aRouteButtons)
        routeButton.routeOn=false;
    }
      
  } // update
    
} // TrackButton Class