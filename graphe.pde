import java.util.Arrays;

PImage original = null;

Node nodes[];
boolean connections[][];
float radius = 25;
int bgColor = 30;
boolean graphMode = true;
int padding = 50;
int maxIterations = 1000;
float minimum_distance = 200;
float deltaTime;
float lastTime;

void setup() {
  size(300, 300);
  surface.setResizable(true);
  surface.setSize((int) (displayWidth * 0.8), (int) (displayHeight * 0.8));
  surface.setLocation(50, 50);
  frameRate(120);
  
  initNodes(10);
  initConnections();

  lastTime = millis();
}

void draw() {
  //Update deltaTime
  float current = millis();
  deltaTime = current - lastTime;
  lastTime = current;

  //Update graph
  applyForces();

  background(bgColor);

  if(graphMode){
    //Drawing arcs
    strokeWeight(2);
    stroke(115);
    for(int i=0; i < nodes.length-1; i++){
      for(int j=i+1; j<nodes.length; j++){
        if(isConnected(nodes[i].key, nodes[j].key))
          line(nodes[i].position[0], nodes[i].position[1], nodes[j].position[0], nodes[j].position[1]);
      }
    }

    //Drawing Nodes
    radius = 40;
    fill(bgColor);
    strokeWeight(3);
    stroke(#7445b5);
    textAlign(CENTER, CENTER);
    for(int i=0; i<nodes.length; i++){
      fill(bgColor);
      circle(nodes[i].position[0], nodes[i].position[1], radius);
      textSize(18);
      fill(255);
      text(nodes[i].key, nodes[i].position[0], nodes[i].position[1]); 
    }
  }
  else{
    int length = width - 4*(padding);
    float lineHeight = height*7/8;

    //Drawing arcs
    noFill();
    strokeWeight(2);
    stroke(#ff6476);
    for(int i=0; i<nodes.length-1; i++){
      for(int j=i+1; j<nodes.length; j++){
        if(isConnected(nodes[i].key, nodes[j].key)){
          radius = (j-i)*length/(nodes.length-1);
          float center = 2*padding + (i+j)*length/(2*(nodes.length-1));
          arc(center, lineHeight, radius, radius, (float) Math.PI, (float) Math.PI*2);
        }
      }
    }
    
    //Drawing Nodes
      //Line
      radius = 16;
      strokeWeight(3);
      stroke(#f1e3ff);
      line(padding, lineHeight, width - padding, lineHeight);

      //Nodes
      textAlign(CENTER);
      for(int i=0; i<nodes.length; i++){
        fill(#9036ff);
        noStroke();
        int position = 2*padding + i*(length)/(nodes.length-1);
        circle(position, lineHeight, radius);
        textSize(24);
        fill(255);
        text(nodes[i].key, position, lineHeight + 41);
      }
  }

  //Display commands
  textAlign(TOP);
  textSize(25);
  fill(255);
  text("Entrer: Changer de mode  |  Espace: Graphe aléatoire  |  M: Minimiser hauteur d'arcs  |  R: Repositionner noeuds aléatoirement", 10, 35); 
}

void minimizeDistances(){ //minmize height of arcs in the arc diagram
  int nbNeighbours[] = new int[nodes.length];
  int state[] = new int[nodes.length];

  int iterations = 0;

  while(iterations < maxIterations){
    for(int i=0; i<nodes.length; i++){
      state[i] = nodes[i].key;
      nodes[i].distances = 0;
      nbNeighbours[i] = 1;
    }

    for(int i=0; i<nodes.length-1; i++){
        for(int j=i+1; j<nodes.length; j++){
          if(isConnected(nodes[i].key, nodes[j].key)){
            nodes[i].distances += j;
            nodes[j].distances += i;

            nbNeighbours[i]++;
            nbNeighbours[j]++;
          }
        }

        nodes[i].distances /= nbNeighbours[i];
    }

    Arrays.sort(nodes);

    boolean changed = false;
  
    for(int i=0; i<nodes.length; i++)
    {
      if(nodes[i].key != state[i])
      {
        changed = true;
        break;
      }
    }

    iterations++;
    if(!changed) return;
  }
}

void applyForces(){
  float center[] = new float[]{width/2.0, height/2.0};

  for(int i=0; i < nodes.length; i++){
    nodes[i].velocity = new float[]{0, 0};

    //Apply attraction to center
    float directionVec[] = vecDifference(center, nodes[i].position);
    float distance = sqrt((float)(Math.pow(directionVec[0], 2) + Math.pow(directionVec[1], 2)));
    distance = Math.max(distance, 0.1);
    float orientation[] = new float[]{directionVec[0]/distance, directionVec[1]/distance};
    nodes[i].velocity = vecSum(nodes[i].velocity, scale(orientation, (float)(1.0*Math.log(distance/minimum_distance))));
    
    //Forces between nodes
    for(int j = 1; j<nodes.length; j++){
      directionVec = vecDifference(nodes[j].position, nodes[i].position);
      distance = sqrt((float)(Math.pow(directionVec[0], 2) + Math.pow(directionVec[1], 2)));
      distance = Math.max(distance, 0.1);
      orientation = new float[]{directionVec[0]/distance, directionVec[1]/distance};

      if(isConnected(nodes[i].key, nodes[j].key)){ //Attraction
        nodes[i].velocity = vecSum(nodes[i].velocity, scale(orientation, (float)(1.0*Math.log(distance/minimum_distance))));
      }

      //Replusion
      nodes[i].velocity = vecSum(nodes[i].velocity, scale(orientation, (float)(-10000.0/Math.pow(distance, 2))));
    }

    //Update position
    nodes[i].velocity = capVelocity(nodes[i].velocity, 1);
    nodes[i].position = vecSum(nodes[i].position, scale(nodes[i].velocity, 0.625*deltaTime));

    //Reposition nodes inside window
    if(nodes[i].position[0] < 0) nodes[i].position[0] = 0;
    if(nodes[i].position[1] < 0) nodes[i].position[1] = 0;
    if(nodes[i].position[0] >= width) nodes[i].position[0] = width-2;
    if(nodes[i].position[1] >= height) nodes[i].position[1] = height-2;
  }

}

void randomizePositions(){
  for(int i=0; i < nodes.length; i++){
    nodes[i] = new Node(i, random(0, width), random(0, height));
  }
}

float[] scale(float vec[], float s){ //Scales vector vec by a scalar s
  return new float[]{vec[0]*s, vec[1]*s};
}

float[] vecDifference(float a[], float b[]){ //Difference of two vectors
  return new float[]{a[0] - b[0], a[1] - b[1]};
}

float[] vecSum(float a[], float b[]){ //Sum of two vectors
  return new float[]{a[0] + b[0], a[1] + b[1]};
}

void initNodes(int number){
  nodes = new Node[number];
  for(int i=0; i < number; i++){
    nodes[i] = new Node(i, random(0, width), random(0, height));
  }
}

float[] capVelocity(float[] velocity, float max){ //Limits velocity to a maximum
  float distance = sqrt((float)(Math.pow(velocity[0], 2) + Math.pow(velocity[1], 2)));
  distance = Math.max(distance, 0.1);
  float orientation[] = new float[]{velocity[0]/distance, velocity[1]/distance};

  return new float[]{ orientation[0]*Math.max(distance, max), orientation[1]*Math.max(distance, max)};
}

void initConnections(){
  connections = new boolean[nodes.length-1][nodes.length];
  for(int i=0; i < nodes.length-1; i++){
    int nbConnections = 0;

    for(int j=i+1; j<nodes.length; j++){
      if(connections[i][j] = (int(random(10)) > 7)) 
        nbConnections++;
    }

    if(nbConnections == 0){
      int index = i;
      while(index == i){
        index = int(random(nodes.length));
      }

      if(i < index) connections[i][index] = true;
      else connections[index][i] = true;
    }
  }
}

boolean isConnected(int a, int b){
  if(a == b)
    return false;
  if(a < b)
    return connections[a][b];
  else return connections[b][a];
}

void keyPressed()
{    
  switch(key)
  {
    case ' ':  
      initNodes(int(random(7, 15)));
      initConnections();
      break;

    case ENTER:
      graphMode = !graphMode;
      break;

    case 'm':
    case 'M':
      minimizeDistances();
      break;
    
    case 'r':
    case 'R':
      randomizePositions();
      break;
  }
}
