//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Classes for Layouts and Tracks
//
//  Layout - defines a scaled region on the screen into which tracks
//           will be place using scaled coordinates
//
//  Track  - defines a curved or straight piece of track.
//         - placement on layout can be in absolute scaled coordinates
//           or linked to one end of a previously-defined track.
//         - tracks can be linked even across separate layouts
//         - define multiple overlapping tracks to create any type
//           of turnout, crossover, or other complex track
//////////////////////////////////////////////////////////////////////////

class Layout{
  int xCorner, yCorner;
  float sFactor;
  
  Layout(int xCorner, int yCorner, int frameWidth, float layoutWidth, float layoutHeight){
    this.xCorner=xCorner;
    this.yCorner=yCorner;
    sFactor=float(frameWidth)/layoutWidth;   // frameWidth in pixels, layoutWidth in mm, inches, cm, etc.
  } // Layout
  
  Layout(Layout layout){
    this.xCorner=layout.xCorner;
    this.yCorner=layout.yCorner;
    this.sFactor=layout.sFactor;
  } // Layout

  void copy(Layout layout){
    this.xCorner=layout.xCorner;
    this.yCorner=layout.yCorner;
    this.sFactor=layout.sFactor;
  } // copy
    
  boolean equals(Layout layout){
    return((this.xCorner==layout.xCorner)&&(this.yCorner==layout.yCorner)&&(this.sFactor==layout.sFactor));
  } // equals

} // Layout Class

//////////////////////////////////////////////////////////////////////////

class Track extends DccComponent{
  float[] x = new float[2];
  float[] y = new float[2];
  float[] a = new float[2];
  color tColor;
  float xR, yR;
  float r;
  float aStart, aEnd;
  int tStatus=1;         // specfies current track status (0=off/not visible, 1=on/visible)
  int hStatus=0;         // specifies if current track is highlighted (1) or normal (0)
  Layout layout;
  
  Track(Layout layout, float x, float y, float tLength, float angleDeg){
    this.x[0]=x;
    this.y[0]=y;
    this.a[1]=angleDeg/360.0*TWO_PI;
    this.a[0]=this.a[1]+PI;
    if(this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.x[1]=this.x[0]+cos(this.a[1])*tLength;
    this.y[1]=this.y[0]-sin(this.a[1])*tLength;
    this.layout=layout;
    this.tColor=color(255,255,0);
    dccComponents.add(this);
  } // Track - straight, absolute

//////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float tLength, Layout layout){
    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];
    this.a[1]=track.a[trackPoint%2];
    this.a[0]=this.a[1]+PI;
    if(this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.x[1]=this.x[0]+cos(this.a[1])*tLength;
    this.y[1]=this.y[0]-sin(this.a[1])*tLength;
    this.layout=layout;
    this.tColor=color(255,255,0);
    dccComponents.add(this);
  } // Track - straight, relative, Layout specified

//////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float tLength){
    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];
    this.a[1]=track.a[trackPoint%2];
    this.a[0]=this.a[1]+PI;
    if(this.a[0]>=TWO_PI)
      this.a[0]-=TWO_PI;
    this.x[1]=this.x[0]+cos(this.a[1])*tLength;
    this.y[1]=this.y[0]-sin(this.a[1])*tLength;
    this.layout=track.layout;
    this.tColor=color(255,255,0);
    dccComponents.add(this);
  } // Track - straight, relative, no Layout specified

//////////////////////////////////////////////////////////////////////////

  Track(Layout layout, float x, float y, float curveRadius, float curveAngleDeg, float angleDeg){
    float thetaR, thetaA;
    int d;
    
    thetaR=curveAngleDeg/360.0*TWO_PI;
    thetaA=angleDeg/360.0*TWO_PI;
    d=(thetaR>0)?1:-1;
    
    this.x[0]=x;
    this.y[0]=y;

    this.a[0]=thetaA+PI;
    if(this.a[0]>=TWO_PI)
    
      this.a[0]-=TWO_PI;
    this.a[1]=thetaA+thetaR;
    if(this.a[1]>=TWO_PI)
      this.a[1]-=TWO_PI;
    if(this.a[1]<0)
      this.a[1]+=TWO_PI;

    this.r=curveRadius;
    
    this.xR=this.x[0]-d*this.r*sin(thetaA);
    this.yR=this.y[0]-d*this.r*cos(thetaA);
    
    this.x[1]=this.xR+d*this.r*sin(thetaA+thetaR);
    this.y[1]=this.yR+d*this.r*cos(thetaA+thetaR);
    
    if(d==1){
      this.aEnd=PI/2-thetaA;
      this.aStart=this.aEnd-thetaR;
    }else{
      this.aStart=1.5*PI-thetaA;
      this.aEnd=this.aStart-thetaR;
    }

    this.layout=layout;
    this.tColor=color(255,255,0);
    dccComponents.add(this);
  } // Track - curved, absolute
  
//////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float curveRadius, float curveAngleDeg, Layout layout){
    float thetaR, thetaA;
    int d;
    
    thetaR=curveAngleDeg/360.0*TWO_PI;
    thetaA=track.a[trackPoint%2];
    d=(thetaR>0)?1:-1;

    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];
    
    this.a[0]=thetaA+PI;
    if(this.a[0]>=TWO_PI)
    
      this.a[0]-=TWO_PI;
    this.a[1]=thetaA+thetaR;
    if(this.a[1]>=TWO_PI)
      this.a[1]-=TWO_PI;
    if(this.a[1]<0)
      this.a[1]+=TWO_PI;

    this.r=curveRadius;
    
    this.xR=this.x[0]-d*this.r*sin(thetaA);
    this.yR=this.y[0]-d*this.r*cos(thetaA);
    
    this.x[1]=this.xR+d*this.r*sin(thetaA+thetaR);
    this.y[1]=this.yR+d*this.r*cos(thetaA+thetaR);
    
    if(d==1){
      this.aEnd=PI/2-thetaA;
      this.aStart=this.aEnd-thetaR;
    }else{
      this.aStart=1.5*PI-thetaA;
      this.aEnd=this.aStart-thetaR;
    }

    this.layout=layout;
    this.tColor=color(255,255,0);
    dccComponents.add(this);
  } // Track - curved, relative, Layout specified

//////////////////////////////////////////////////////////////////////////

  Track(Track track, int trackPoint, float curveRadius, float curveAngleDeg){
    float thetaR, thetaA;
    int d;
    
    thetaR=curveAngleDeg/360.0*TWO_PI;
    thetaA=track.a[trackPoint%2];
    d=(thetaR>0)?1:-1;

    this.x[0]=track.x[trackPoint%2];
    this.y[0]=track.y[trackPoint%2];
    
    this.a[0]=thetaA+PI;
    if(this.a[0]>=TWO_PI)
    
      this.a[0]-=TWO_PI;
    this.a[1]=thetaA+thetaR;
    if(this.a[1]>=TWO_PI)
      this.a[1]-=TWO_PI;
    if(this.a[1]<0)
      this.a[1]+=TWO_PI;

    this.r=curveRadius;
    
    this.xR=this.x[0]-d*this.r*sin(thetaA);
    this.yR=this.y[0]-d*this.r*cos(thetaA);
    
    this.x[1]=this.xR+d*this.r*sin(thetaA+thetaR);
    this.y[1]=this.yR+d*this.r*cos(thetaA+thetaR);
    
    if(d==1){
      this.aEnd=PI/2-thetaA;
      this.aStart=this.aEnd-thetaR;
    }else{
      this.aStart=1.5*PI-thetaA;
      this.aEnd=this.aStart-thetaR;
    }

    this.layout=track.layout;
    this.tColor=color(255,255,0);
    dccComponents.add(this);
  } // Track - curved, relative, no Layout specified

//////////////////////////////////////////////////////////////////////////

  void display(){
    
    if(tStatus==1){                // track is visible
      if(hStatus==1)                // track is highlighted
        stroke(color(0,255,0));
      else
        stroke(color(255,255,0));
    } else{                          // track is not visible
      if(hStatus==1)                // track is highlighted
        stroke(color(255,0,0));
      else
        stroke(color(80,80,0));
    }
      
    strokeWeight(3);
    ellipseMode(RADIUS);
    noFill();
    if(r==0){
      line(x[0]*layout.sFactor+layout.xCorner,y[0]*layout.sFactor+layout.yCorner,x[1]*layout.sFactor+layout.xCorner,y[1]*layout.sFactor+layout.yCorner);
    }
    else{
      arc(xR*layout.sFactor+layout.xCorner,yR*layout.sFactor+layout.yCorner,r*layout.sFactor,r*layout.sFactor,aStart,aEnd);
    }
  } // display()

} // Track Class

//////////////////////////////////////////////////////////////////////////