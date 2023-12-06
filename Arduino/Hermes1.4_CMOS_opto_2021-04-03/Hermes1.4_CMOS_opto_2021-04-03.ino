/* WHAT'S NEW
    2018/10/18 Hermes 1.1 Added the new adaptive threshold.
    2018/10/23 Hermes 1.2 Changed the calibration loops
    2019/11/14 Hermes 1.3 Added serial communication and generalized the stimulation to be used for triggering the CMOS camera
*/

// ---CONSTANTS----------------------------------------------------------------------------------
const int R = 11;
const int G = 12;
const int B = 13;
const int TTL1 = 5; // to control the camera (if mod=camAc or mod=camPr) or to synchronize ePhys (if mod=classic or mod=opto)
const int pinIN = A0; // Phototransistor analog input
const int TTL2 = 7; // to control either Solis LED or Optogenetics laser

// ---variables----------------------------------------------------------------------------------
  //basic variables
unsigned long idleTime = 200; // the time (in ms) the system stays idle after triggering a TTL
unsigned long trialPeriod = 200; // the time between two puffs (ms)
unsigned long t0; //stimulus time
unsigned long serial_delay = 1000; //delay between serial input and TTL firing (in ms)
unsigned long TTL_time = 2000; //µs
unsigned long led_time = 10000; //µs. If led_time=0, then the LED is not turned ON at all.
bool outEnabled = true; //send a TTL output at the beginning of each trial, or when a stimuls
                        //appears on the screen (to be recorded or to trigger an external stimulator)
bool solisEnabled = false; //true if the Solis has to be turned on by Arduino

  //variables for multiple frames triggering (PCO)
unsigned long frameP = 30000; //µs, is the framerate when triggering every frame
unsigned long puffP = 1000000; //µs
unsigned long nFrames = 1; // number of cmos ttl per stimulus
unsigned long iFrame; // index of cmos ttl
int nTrials = 1;
volatile bool stopTrig = false;

  //variables for optogeneitc stimulation
unsigned long optoStart = 200; //ms
unsigned long optoDur = 800; //ms
unsigned long optoPer = 1000; //ms
unsigned long nStim = 1; // number of optogen pulses
 
  //variables for the phototransistor
double whiteval=1, blackval=1, val, thr;
unsigned long calibTime = 5000000; // calibration time in µs
bool calibW_done, calibB_done;
double thrRatio = 0.8;// MUST be between 0 and 1. The ratio between the threshold-white distance divided by the black-white distance (thr-whiteval/(blackval-whiteval))
  // Conservative value (best one) = 0.5. old value was 0.75. High value: 0.999 (IT WORKS)

  //helper variables
int idxA, idxB; //useful for parsing the serial input
String mod = "o"; //useful for parsing the serial input
bool synch = true; //useful for triggering stimulation upon serial input
unsigned long t_now; //for debug only

// Pointers to functions------------------------------------------------------------------------------
void (*f1)();
void (*f2)();
void (*f3)();

// Calibration function-------------------------------------------------------------------------------
void calibrate_white(){
  Serial.println("White calibration starts");
  unsigned long startTime, i;
  // --- BEGIN WHITE CALIBRATION
  whiteval = 5000; // largest possible value, in mV
  startTime = micros();
  while (micros() < startTime + calibTime) {
    val = analogRead(pinIN) * 4.9; // 4.9 is a conversion factor from 0-255 bits to 0-5000 mV
    if (val < whiteval) {
      whiteval = val;
    }
    // Red LED blinks at 4 Hz (blinking purple)
    if ((micros() - startTime) % 250000 < 125000) { // Red LED turns onset
      digitalWrite(R, HIGH);
    }
    else { // Red LED turns off
      digitalWrite(R, LOW);
    }
  }
  calibW_done = true;
  // --- END WHITE CALIBRATION

  // The red LED is ON, indicating that the threshold is not updated.
  digitalWrite(R, HIGH);
}

void calibrate_black(){
  Serial.println("Black calibration starts");
  unsigned long startTime, i;
   // --- BEGIN BLACK CALIBRATION
  blackval = 5000;
  startTime = micros();
  while (micros() < startTime + calibTime) {
    val = analogRead(pinIN) * 4.9;
    if (val < blackval) {
      blackval = val;
    }
    // Red LED blinks at 4 Hz (blinking purple)
    if ((micros() - startTime) % 250000 < 125000) { // Red LED turns on
      digitalWrite(R, HIGH);
    }
    else { // Red LED turns off
      digitalWrite(R, LOW);
    }
  }
  calibB_done = true;  
  // --- END BLACK CALIBRATION
  
  // The red LED is ON, indicating that the threshold is not updated.
  digitalWrite(R, HIGH);
}

void compute_threshold(){
  // The threshold is finally set:
  thr = thrRatio * (blackval - whiteval) + whiteval;
    // The ratio is a number between 0 and 1. It's the distance of the threshold from the white value, normalized over the distance between the white and black values.

  if (calibW_done && calibB_done) {
    // The calibration is over. The green LED stays on, indicating that Hermes is ready
    digitalWrite(R, LOW);
    digitalWrite(B, LOW);
    digitalWrite(G, HIGH);
  }else{
    // Another step is needed. The red LED is ON, indicating that the threshold is not updated.
    digitalWrite(R, HIGH);
    digitalWrite(B, LOW);
    digitalWrite(G, LOW);
  }

  // Serial Monitor Check begin(uncomment included code for checking)
//  Serial.print("whiteval = ");
//  Serial.println(whiteval);
//  Serial.print("blackval = ");
//  Serial.println(blackval);
//  Serial.print("thr = ");
//  Serial.println(thr);
  //  Serial.end();
  // Serial Monitor Check end (uncomment included code for checking)
}


// Let's define the functions for building up our loop function.---------------------------------------
// Let's start with the functions that can be assigned to *f1, which is the main function of the loop
// and does just two things: 1) it checks if a condition is true or not. 2) If it is true, it calls f2.
void f_default(){
  //do nothing
  
}

void check_photo() {
  // calls f2 if a visual stimulus appears
  val = analogRead(pinIN) * 4.9;
  if(val < thr){ //Phototransistor
    t0=micros();
//    Serial.println(t0);
    f2();
//    t0_millis = (unsigned long)(round(double(t0)/1000));
//    Serial.println(t0_millis+idleTime);
//    Serial.println(millis());
    unsigned long idleTime_micros = idleTime*1000;
    while(micros()<(t0+idleTime_micros)){
      //just wait, not to respond twice to the same stimulus
    }
  }
}

void check_serial() {
  // calls f2 if Arduino receive a proper serial message
  if (synch){
    synch = false;

    if(solisEnabled){
      digitalWrite(TTL2, HIGH); //turn the LED on
      delay((unsigned long) (serial_delay)); // serial_delay must be expressed in ms
    }
    
    //for (iTrial = 1; iTrial <= nTrials; iTrial++){
    int iTrial=1;
    while(iTrial <= nTrials){
      t0=micros(); //save the starting time
      f2(); //call trigger_nFrames
      iTrial++; //update the counter
      while(millis()<round(t0/1000)+trialPeriod); //just wait according to the trial period
    }

    if(solisEnabled){
      delay(500);
      digitalWrite(TTL2, LOW);
    }
    
    Serial.println("end of stim");
  }
}

// The followings are the functions that can be assigned to f2. They send TTL signals.-----------------
void trigger_nFrames(){
  
  iFrame = 0;
  bool nFramesAcquired = false;
  //while((iFrame<=nFrames-1) && !stopTrig){
  while(!nFramesAcquired && !stopTrig){  
    digitalWrite(TTL1, HIGH); //start imaging setting cMOS TTL to HIGH
    //if ((iFrame == 1) && outEnabled) digitalWrite(outTTL, HIGH); //send out TTL (to start a stimuls or to be recorded)
    unsigned long tnow = micros();
    while (micros() < tnow + TTL_time ){
      //just wait
    }
    digitalWrite(TTL1, LOW); //stop cMOS TTL
    //if ((iFrame == 1) && outEnabled) digitalWrite(outTTL, LOW); //stop out TTL

    //if(! mod.equals("prev")) iFrame++; //if a preview is running go on until a stop command comes
    iFrame++;
    if( (!mod.equals("prev"))&&(iFrame>=nFrames) ){
        nFramesAcquired = true;
    }
    
    callParser(); //check for a stop command
    
    while (micros() < (t0 + frameP * iFrame) ){
      // do  nothing: wait until the next frame
    }
  }
}

void trigger_opto(){
  digitalWrite(TTL1, HIGH); //report stimulus onset
  //if ((iFrame == 1) && outEnabled) digitalWrite(outTTL, HIGH); //send out TTL (to start a stimuls or to be recorded)
  unsigned long tnow = micros();
  while (micros() < tnow + TTL_time ){
    //just wait
  }
  digitalWrite(TTL1, LOW);
  
  // wait for optogenetics
  //  Serial.println(millis());
    while (micros() < t0 + 1000*optoStart){
      //just wait
    }
    
  unsigned long i;
  for (i==1;i<=nStim;i++){                                                                                                                                                                                                                                                                                                                                                          
    // now turn the optogenetics laser ON
    digitalWrite(TTL2, HIGH);
  //  Serial.println(millis());
    while (micros() < t0 + 1000*optoStart + 1000*optoDur +1000*optoPer*(i-1)){
      //just wait
    }
    digitalWrite(TTL2, LOW);
  //  Serial.println(millis());
  //  Serial.println();
    while (micros() < t0 + 1000*optoStart + 1000*optoPer*(i)){
      //just wait
    }
  }
}


void trigger_classic(){
  digitalWrite(TTL1, HIGH); //report stimulus onset
  //if ((iFrame == 1) && outEnabled) digitalWrite(outTTL, HIGH); //send out TTL (to start a stimuls or to be recorded)
  unsigned long tnow = micros();
  while (micros() < tnow + TTL_time ){
    //just wait
  }
  digitalWrite(TTL1, LOW);
}

// Procedures for parsing strings coming from serial communication-------------------------------------
void parseSerial(String str) {
  // Visualize if the input string is correct
  // Serial.println(str);
  // parse the string and assign parameters
  String substr;
  int idxStart = 0;
  int l = str.length();
  while(idxStart < l-1){
    int idxStop = str.indexOf(",", idxStart);
    if (idxStop==-1){
      idxStop = l-1;
    }
    substr = str.substring(idxStart, idxStop);
    assignParsedStr(substr); //identify the variable-value couple and perform the assignment
    idxStart = idxStop+1;
  }
}

void assignParsedStr(String substr){

  Serial.println(substr);
  // separe the name and the value
  int idxSep = substr.indexOf("=");
  String sub1 = substr.substring(0,idxSep);
  String sub2 = substr.substring(idxSep+1,substr.length());
  Serial.println(sub1);
  Serial.println(sub2);
  
  // assign
  if(sub1.equals("trig")) {
    String trig = sub2;
    if (trig.equals("p")){ //phototransistor
      f1 = &check_photo;
      digitalWrite(R,LOW);
      digitalWrite(G,HIGH);
      digitalWrite(B,LOW);
    }
    if (trig.equals("s")){ //serial command from Matlab
      f1 = &check_serial;
      synch = false;
      stopTrig = false;
      digitalWrite(R,LOW);
      digitalWrite(G,LOW);
      digitalWrite(B,HIGH);
    }
  }
  
  if(sub1.equals("mod")) {
    mod = sub2;
    if (mod.equals("camAc")){ //trigger nFrames for acquisition
      f2 = &trigger_nFrames;
      stopTrig = false;
      if(solisEnabled) digitalWrite(TTL2,HIGH); //turn the Solis ON if visual stimulation is
                                                // coupled with widefield imaging. 
    }
    if (mod.equals("camPr")){ //cmos preview
      f2 = &trigger_nFrames;
      nFrames = ~((unsigned long) 0);
      nTrials = 1;
      synch = false;
      stopTrig = false;
    }
    if (mod.equals("opto")){ //optogenetics
      f2 = &trigger_opto;        
    }
    if (mod.equals("classic")){ //classic mode: just send one TTL
      f2 = &trigger_classic;        
    }
  }

  if(sub1.equals("cal")){
    // calibration
    if(sub2.equals("w")) calibrate_white();
    if(sub2.equals("b")) calibrate_black();
    compute_threshold();
  }

  if(sub1.equals("stopTrig")){ //stop triggering
    if(sub2.equals("1")){ //just to be sure
      synch = false;
      stopTrig = true;
      digitalWrite(R,LOW);
      if(solisEnabled){
        digitalWrite(TTL2,LOW); //turn off the Solis
      }
    }
  }

  if(sub1.equals("query")){ //ask the value of a variable
    if(sub2.equals("threshold")){ 
      String outString = "threshold = ";
      Serial.println(outString+thr);
    }
    if(sub2.equals("frameP")){
      String outString = "frameP = ";
      Serial.println(outString+frameP);
    }
    if(sub2.equals("nFrames")){
      String outString = "nFrames = ";
      String outString2 = String(nFrames);
      Serial.println(outString+outString2);
    }
    if(sub2.equals("idleTime")){
      String outString = "idleTime = ";
      String outString2 = String(idleTime);
      Serial.println(outString+outString2);
    }
  }

  if(sub1.equals("synch")){ //start cmos
    if(sub2.equals("1")){ //just to be sure
      synch = true;
    }
  }

  if(sub1.equals("solisEnabled")){ //start cmos
    if(sub2.equals("1")){
      solisEnabled = true;
    }
    if(sub2.equals("0")){
      solisEnabled = false;
    }
  }
  
  if(sub1.equals("TTL_time")) TTL_time = (unsigned long)sub2.toDouble(); //expressed in micros
  if(sub1.equals("frameP")) frameP = (unsigned long)sub2.toDouble(); //expressed in micros
  if(sub1.equals("idleTime")) idleTime = (unsigned long)sub2.toDouble(); //expressed in ms
  if(sub1.equals("serial_delay")) serial_delay = (unsigned long)sub2.toDouble(); //expressed in ms
  if(sub1.equals("trialPeriod")) trialPeriod = (unsigned long)sub2.toDouble(); //expressed in ms
  if(sub1.equals("nFrames")) nFrames = (unsigned long)sub2.toDouble();
  if(sub1.equals("nTrials")) nTrials = sub2.toInt();
  if(sub1.equals("optoStart")) optoStart = (unsigned long)sub2.toDouble();
  if(sub1.equals("optoDur")) optoDur = (unsigned long)sub2.toDouble();
  if(sub1.equals("optoPer")) optoPer = (unsigned long)sub2.toDouble();
  if(sub1.equals("nStim")) nStim = (unsigned long)sub2.toDouble();
}

//-----------------------------------------------------------------------------------------------------
void setup() {
  const int readBtn = 3; // pin that is read to check if button is pressed
  pinMode(TTL1, OUTPUT);
  digitalWrite(TTL1, LOW);
  pinMode(TTL2, OUTPUT);
  digitalWrite(TTL2, LOW);
  pinMode(R, OUTPUT);
  pinMode(G, OUTPUT);
  pinMode(B, OUTPUT);
  digitalWrite(R, LOW);
  digitalWrite(G, LOW);
  digitalWrite(B, LOW);
  pinMode(readBtn, INPUT_PULLUP);

  // estabilish a serial communication
  Serial.begin(57600);
  delay(1000);
  Serial.println("<Arduino is ready>");
  String reply = Serial.readString(); // look for an answer
  bool correctReply = true; //what???

  calibW_done = false;
  calibB_done = false;

  if(!correctReply){
    // Hermes is not controlled vAia serial port, therefore the calibration
    // has to be IMPLEMENTED manually.
    digitalWrite(R, HIGH);
    
    //  WHITE CALIBRATION CAN START
    //  Wait for the button to be pressed
    while (digitalRead(readBtn) == HIGH) {}
    delay(500);
    calibrate_white();
    
    //  BLACK CALIBRATION CAN START
    //  Wait for the button to be pressed
    while (digitalRead(readBtn) == HIGH) {}
    delay(500);
    calibrate_black();

    //  COMPUTE THE THRESHOLD
    compute_threshold();

    // Assign f1 and f2. In this way, Hermes works as always
    f1 = &check_photo;
    f2 = &trigger_classic;
    
  }else{
    
    // do nothing and wait for instructions.
    f1 = &f_default;
    f2 = &f_default;
    digitalWrite(R, HIGH);
  }
}

//-----------------------------------------------------------------------------------------------------
void loop() {
  // put your main code here, to run repeatedly:
  f1();
}

//-----------------------------------------------------------------------------------------------------
void serialEvent() {
  // at the end of every loop, Hermes looks for serial messages. If a serial message has been received,
  // this function is executed.
  callParser();
}

void callParser() {
  while (Serial.available()) {
    
    String inStr = Serial.readString();

    parseSerial(inStr);

    Serial.println("Roger roger");
  }
}
