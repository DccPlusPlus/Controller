//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Class for Route Button
//
//  RouteButton  -  creates a button to activate one or more Track Buttons
//                  that in turn set one or more TURNOUTS or CROSSOVERS to either an
//                  open or closed position representing a specific track route
//               -  tracks may also be added to a route button so that they are highlighted
//                  on the screen when the route button is first selected
//               -  track highlights will be color-coded to indicate whether each
//                  turnout or crossover that in in the route is already set properly,
//                  or needs to be toggled if that route is activiated
//
//               -  two types of route buttons are supported:
//
//                  * large stand-alone button with a text label indicated the name of the route
//                  * small button placed on a track where the route is obvious and does
//                    not require a name (such as at the end of a siding)
//
//////////////////////////////////////////////////////////////////////////

class RouteButton extends DccComponent{
  int xPos, yPos;
  int kWidth, kHeight;
  String label="";
  boolean routeOn=false;
  ArrayList<TrackButton> aTrackButtons = new ArrayList<TrackButton>();
  ArrayList<TrackButton> bTrackButtons = new ArrayList<TrackButton>();
  ArrayList<Track> rTracks = new ArrayList<Track>();
  
  RouteButton(Track refTrack, int kWidth, int kHeight){
    this.xPos=int((refTrack.x[0]+refTrack.x[1])/2.0*refTrack.layout.sFactor+refTrack.layout.xCorner);
    this.yPos=int((refTrack.y[0]+refTrack.y[1])/2.0*refTrack.layout.sFactor+refTrack.layout.yCorner);
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    dccComponents.add(this);
  }
    
  RouteButton(int xPos, int yPos, int kWidth, int kHeight, String label){
    this.xPos=xPos;
    this.yPos=yPos;
    this.kWidth=kWidth;
    this.kHeight=kHeight;
    this.label=label;
    dccComponents.add(this);
    
  } // RouteButton

//////////////////////////////////////////////////////////////////////////

  void addTrackButton(TrackButton trackButton, int tPos){
    if(tPos==0){                       // specifies that this track button should be set to A when route selected
      aTrackButtons.add(trackButton);
      trackButton.aRouteButtons.add(this);
    } else if (tPos==1) {              // specifies that this track button should be set to B when route selected
      bTrackButtons.add(trackButton);
      trackButton.bRouteButtons.add(this);
    }
  }

//////////////////////////////////////////////////////////////////////////

  void addTrack(Track track){
      rTracks.add(track);
  }

//////////////////////////////////////////////////////////////////////////
  
  void display(){    
    if(label.equals("")){
      ellipseMode(CENTER);
      if(routeOn)
        fill(color(0,255,0));
      else
        fill(color(0,150,0));
      noStroke();
      ellipse(xPos,yPos,kWidth/2,kHeight/2);
    } else{
      ellipseMode(CENTER);
      if(routeOn)
        fill(color(0,200,200));
      else
        fill(color(0,100,100));
      noStroke();
      ellipse(xPos,yPos,kWidth,kHeight);
      textFont(buttonFont,12);
      textAlign(CENTER,CENTER);
      fill(color(0));
      text(label,xPos,yPos);
    }    
  } // display
  
//////////////////////////////////////////////////////////////////////////

  void check(){
    if(selectedComponent==null && (mouseX-xPos)*(mouseX-xPos)/(kWidth*kWidth/4.0)+(mouseY-yPos)*(mouseY-yPos)/(kHeight*kHeight/4.0)<=1){
      cursorType=HAND;
      selectedComponent=this;
      for(Track track : rTracks){
        track.hStatus=1;
      }
    }
    
    else if(previousComponent==this){
      for(Track track : rTracks){
        track.hStatus=0;
      }
    }
    
  } // check
  
//////////////////////////////////////////////////////////////////////////

  void pressed(){
    for(TrackButton trackButton : aTrackButtons){
      if(trackButton.rEnabled)
        trackButton.pressed(0);
    }
    for(TrackButton trackButton : bTrackButtons){
      if(trackButton.rEnabled)
        trackButton.pressed(1);
    }
    routeOn=true;
  } // pressed

//////////////////////////////////////////////////////////////////////////

  void shiftPressed(){
    for(TrackButton trackButton : aTrackButtons){
      if(trackButton.rEnabled)
        trackButton.pressed(1);
    }
    for(TrackButton trackButton : bTrackButtons){
      if(trackButton.rEnabled)
        trackButton.pressed(0);
    }
    routeOn=false;
  } // shiftPressed
    
} // RouteButton Class