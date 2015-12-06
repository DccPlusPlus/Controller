//////////////////////////////////////////////////////////////////////////
//  DCC++ CONTROLLER: Constants
//////////////////////////////////////////////////////////////////////////

enum ButtonType{
  NORMAL,
  ONESHOT,
  HOLD,
  REVERSE,
  T_COMMAND,
  Z_COMMAND
}

enum InputType{
  BIN ("[01]"),
  DEC ("[0-9]"),
  HEX ("[A-Fa-f0-9]");
  
  final String regexp;
  InputType(String regexp){
    this.regexp=regexp;
  }
}

enum CabFunction{
  F_LIGHT,
  R_LIGHT,
  D_LIGHT,
  BELL,
  HORN,
  S_HORN
}

enum ThrottleSpeed{
  FULL,
  SLOW,
  STOP,
  REVERSE,
  REVERSE_SLOW;
  
  static ThrottleSpeed index(String findName){
    for(ThrottleSpeed p : ThrottleSpeed.values()){
      if(p.name().equals(findName))
        return(p);
    }
    return(null);
  }
}

enum AutoProgram{
  NONE ("NONE"),
  ALL_CABS_RUN ("ALL CABS RUN"),
  ALL_CABS_PARK ("ALL CABS PARK"),
  SINGLE_CAB_PARK ("SINGLE CAB PARK"),
  AUTO_CLEAN ("AUTO CLEAN"),
  SINGLE_CAB_RUN ("SINGLE CAB RUN");
  
  String name;
  AutoProgram(String name){
    this.name=name;
  }
  static AutoProgram index(String findName){
    for(AutoProgram p : AutoProgram.values()){
      if(p.name.equals(findName))
        return(p);
    }
    return(null);
  }
  
  boolean equals(AutoProgram p){
    return(this==p);
  }
    
}