ArrayList<Thread> threads;
ArrayList<Ball> particles;
PVector grav = new PVector(0,1);
int yStart = 100;
int num_stiches = 10;
float mass = 50;
float restLen = 10;
int rows = 20;
int cols = 40;
float k = 1.1; // stretchiness of the cloth

PImage img;


float dt = 0.05;
void setup() {
  size(800, 800, P3D);
  lights();
  img = loadImage("cloth.jpg");
  threads = new ArrayList<Thread>();
  particles = new ArrayList<Ball>();
  int midWidth = (int) (width/2 - (cols * restLen)/2);
  for(int i = 0; i <= rows; i++){
    for(int j = 0; j <= cols; j++){
      Ball b = new Ball(new PVector((midWidth + j * restLen),(i * restLen + yStart)));    
      if(j!=0){
        b.attachTo(particles.get(particles.size()-1), restLen,k);
      }
      if(i!=0){
        b.attachTo(particles.get((i-1) * (cols + 1) + j),restLen,k);
      }      
      if(i == 0){
        println(b.location.x);
        b.pinTo(b.location);
      }
      particles.add(b);           
    }
  }
}

void draw() {
  background(255);
  
  for(int i = 0; i < 15; i++){
    for(int j = 0; j < particles.size(); j++){
      particles.get(j).solve();
    }
  }
  
  for(int i = 0; i < particles.size(); i++){
    Ball b = particles.get(i);
    if(keyPressed && keyCode == 37){
      println(b.vel.x);
      b.vel.x+=1;
    }
    if(keyPressed && keyCode == 39){
      b.vel.x-=1;
    }  
    if(keyPressed && keyCode == DOWN){
      b.vel.y+=1;
    }
    if(keyPressed && keyCode == UP){
      grav.y = 1;
    }
    
    b.update(dt);
  }
  for(int i = 0; i < particles.size(); i++){
    beginShape();
    texture(img);
    particles.get(i).display();
    endShape();
  }
  if(mousePressed){
    int x = floor(map(mouseX,particles.get(0).location.x,particles.get(cols).location.x,0,cols));
    int y = floor(map(mouseY,particles.get(0).location.y,particles.get(particles.size()-1).location.y,0,rows));
    if(x >= 0 && y >= 0 && x <= cols && y <= rows){
      println(x * rows + y);
      Ball b = particles.get(y * cols + x + 1);
      b.fill = 0;
      if(b.links.size() > 0){
        for(int i = 0; i < b.links.size(); i++){
          b.removeLink(b.links.get(i));
        }
      }
    println(x + " " + y);
    println(particles.get(0).location.y);
    }
  }

}




class Ball{
  PVector vel;
  PVector location;
  PVector lastLoc;
  PVector nextLoc;
  PVector acc;
  float gravity = 100;
  float mass = 1;
  float k = 20;
  float fill = 255;
  ArrayList<Link>links = new ArrayList();

  float kv = 50;
  float forceY;
  float forceX;
  
  boolean pinned = false;
  PVector pinLocation = new PVector(0,0);
  
  Ball(PVector loc) { 
    location = new PVector(loc.x,loc.y);
    lastLoc = new PVector(loc.x,loc.y);
    acc = new PVector(0,0);
    vel = new PVector(0,0);
    nextLoc = new PVector(0,0);
    //mass = m;
    //gravity = g;
  }
  
  void update(float dt){
    
    //PVector stringF = new PVector(0,-k * (location.y - yStart) - restLen);
    //float forceY = -k * (location.y - lastLoc.y - restLen) + -kv * (vel.y) + stringF.y;
    //float forceX = -k * (location.x - lastLoc.x - restLen) + -kv * (vel.x) + stringF.x;
    ////PVector force = PVector.add(new PVector(0,mass*gravity),stringF);
    //PVector force = new PVector(forceX, forceY);
    //println(force.x + " " + force.y);
    //acc.x+= (force.x/mass);
    //acc.y+= (force.y/mass);

    vel.x += location.x - lastLoc.x;
    vel.y += location.y - lastLoc.y + grav.y;
    acc.sub(PVector.mult(vel,k/mass));
    nextLoc.x = location.x + vel.x + .5 * acc.x * dt * dt;
    nextLoc.y = location.y + vel.y + .5 * acc.y * dt * dt;
    lastLoc.set(location);
    location.set(nextLoc);
    acc.mult(0);
    vel.mult(0);
  }
 
  void removeLink (Link lnk) {
    links.remove(lnk);
  }  
  void applyForce(PVector force){
    PVector f = force;
    f.div(mass);
    acc.add(f);
  }
  void display() {
    stroke(0,fill,0);
    if(links.size() > 0){
      for(int i = 0; i < links.size(); i++){
        links.get(i).draw();
      }
    }else{
      stroke(0,fill,0);
      strokeWeight(1);
      point(location.x,location.y);
    }
    
  }
  void attachTo (Ball P, float restingDist, float stiff) {
    Link lnk = new Link(this, P, restingDist, stiff);
    links.add(lnk);
  }
  
  void solve(){
    for(int i = 0; i < links.size(); i++){
      links.get(i).constraintSolve();
    }
    if(pinned){
      location.x = pinLocation.x;
      location.y = pinLocation.y;
    }
  }
  void pinTo (PVector location) {
    pinned = true;
    pinLocation.set(location);
  }
}



class Link {
  float restingDistance;
  float stiffness;
  
  Ball p1;
  Ball p2;
  
  // the scalars are how much "tug" the particles have on each other
  // this takes into account masses and stiffness, and are set in the Link constructor
  float scalarP1;
  float scalarP2;
  
  // if you want this link to be invisible, set this to false
  boolean drawThis = true;
  
  Link (Ball which1, Ball which2, float restingDist, float stiff) {
    p1 = which1; // when you set one object to another, it's pretty much a reference. 
    p2 = which2; // Anything that'll happen to p1 or p2 in here will happen to the paticles in our array
    
    restingDistance = restingDist;
    stiffness = stiff;
    
    // although there are no differences in masses for the curtain, 
    // this opens up possibilities in the future for if we were to have a fabric with particles of different weights
    float im1 = 1 / p1.mass; // inverse mass quantities
    float im2 = 1 / p2.mass;
    scalarP1 = (im1 / (im1 + im2)) * stiffness;
    scalarP2 = (im2 / (im1 + im2)) * stiffness;
  }
  
  void constraintSolve () {
    // calculate the distance between the two particles
    PVector delta = PVector.sub(p1.location, p2.location);

    float d = sqrt(delta.x * delta.x + delta.y * delta.y);
    float difference = (restingDistance - d) / d;

    // P1.position += delta * scalarP1 * difference
    // P2.position -= delta * scalarP2 * difference
    p1.location.add(PVector.mult(delta, scalarP1 * difference));
    p2.location.sub(PVector.mult(delta, scalarP2 * difference));
  }

  void draw () {
    if (drawThis)
      line(p1.location.x, p1.location.y, p2.location.x, p2.location.y);
  }
}
