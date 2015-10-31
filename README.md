What’s DCC++
------------

DCC++ is an open-source hardware and software system for the operation of DCC-equipped model railroads.

The system consists of two parts, the DCC++ Base Station and the DCC++ Controller.

The DCC++ Base Station consists of an Arduino micro controller fitted with an Arduino Motor Shield that can be connected directly to the tracks of a model railroad.

The DCC++ Controller provides operators with a customizable GUI to control their model railroad.  It is written in Java using the Processing graphics library and IDE and communicates with the DCC++ Base Station via a standard serial connection over a USB cable or wireless over BlueTooth.

What’s in this Repository
-------------------------

This repository, Controller, contains a complete DCC++ Graphical User Interface sketch, written in Java, and designed for use within the Processing IDE environment (www.processing.org).  All sketch files are in the folder named DCCpp_Controller.

To utilize this sketch, simply download a zip file of this repository and open the file DCCpp_Controller.pde within the DCCpp_Controller folder using your Processing IDE.  Please do not rename the folder containing the sketch code, nor add any files to that folder.  The Processing IDE relies on the structure and name of the folder to properly display and run the code.

Though this code base is relatively mature and has been tested with the latest version of Processing (3.0.1), it is not as well-commented or documented as the DCC++ Base Station code for the Arduino.

Before using this code, you may wish to visit my DCC++ YouTube channel (see link on main DCC++ GitHub screen) and watch the demo videos showing all the features and functions of this interface.

Use and Customization
---------------------

DCC++ Controller can be used with or withouth a connection to a DCC++ Base Station, though obviously without a Base Station you won't be able to control a model railroad.  However, you would still be able to test out the interface, modify the layout, create turnouts, add and delete cabs, throttles, etc.

All main operating functions are found on the main screen.  Hitting 'h' toggles a help window on and off that contains a list of all other windows that can be opened with similar single-key toggling.  You can also toggle the help window via the question mark in the upper right corner of the screen.

To connect the DCC++ Controller to a DCC++ Arduino Base Station, first connect the Base Station to your PC or Mac via its USB cable.  Then open and run the DCC++ Controller within the Processing Environment.  Hitting 's' will bring up a serial connection window.  Hit the SCAN button and the interface will identify all available serial ports.  Use the arrow keys to select which port contains your DCC++ Arduino Base Station and then hit the CONNECT button.  After 5 or so seconds, a message should appear at the top of the screen indicating connectivity.  If not, please re-check your serial connection and make sure you don't have the Arduino IDE Serial Monitor (or any other serial monitor) opened and connected to the Base Station.  This will block the Controller from connecting to the Arduino since only one serial connection to the Arduino can be opened at a time.

If you do not have an Arduino Base Station, or just want to test out the Controller, you can select "Emulator" from the serial connection window.  This will allow the Controller to operate most functions as if it were connected to a Base Station.

Note that most of the functions on the Controller rely on feedback from the Base Station in order to operate.  This is why the imbedded "Emulator" functionality is needed -- to provide emulated feedback to the Controller.

If you sucessfully connect the Controller to the Base Station, the first thing you may want to test is the "Power" button.  This should turn on and off power to the tracks.  If the Power button lights up when you press it, this means the Controller is properly communicating with the Base Station since the Power button won't light until it receives a confirm from the Base Station.

I have pre-programmed 7 cabs and all of their functions into a single throttle.  You should be able to select any cab button and control the throttle.  However, unless your cab numbers happen to match one of the 7 I have included, you will not be able to operate any of your trains.  Almost all of the code you will need to customize for your own layout can be found in the "controllerConfig" tab of the Processing IDE.  Definitions of the throttle, the cabs, and the cab buttons can be found starting at line 283.  The first cab you'll see defined is #2004 in the following line:

   cab2004 = new CabButton(tAx-125,tAy-150,50,30,150,15,2004,throttleA);

It's okay to leave the name of the variable as cab2004 -- it could be called anything.  The actual cab number is provided in the second-to-last parameter.  Change this from 2004 to match the cab number for one of your locomotives.  Then restart the program (you don't have to restart Processing itself, just the Controller program).  Controller should have remembered your serial settings from before so you wont have to go through the serial scan and connect every time, unless you want to make a change.

Hit the Power button and verifify that it lights up.  Then hit the cab button that now should show the cab number you just modified.  Give the throttle a try.  If all is well, your train should now be moving.

Starting at around line 365 in “configController” you'll find all the code that creates the track layout.  You should be able to modify these to match your own.  The code under the "dTracks" tab should provide some info on the parameters.

Starting at around line 507 you'll find the code for the turnouts.  The routines supporting these functions can be found in the "dRoutes" tab.  Note that each turnout has a uniquely defined ID number.  These numbers must match the ID number of turnouts you defined in the Arduino DCC++ Base Station sketch.  If not, the turnout will not respond on the interface when you click it to switch direction (and obviously will not respond on your layout).   You can define a turnout in the Base Station sketch even if it is not really connected to an accessory decoder, if you'd like to simply test the Controller functionality.

This is a rather complex code base and it's definitely not as clean and tight as the Base Station sketch, but I hope you'll be able to get the gist of things by changing individual parameters and observing the net effect.

Ideally, if others start to utilize this Controller, it would probably make sense to move the customization of the cabs and layout into an XML or JSON parameters file.  A good project for the future...

Enjoy!




