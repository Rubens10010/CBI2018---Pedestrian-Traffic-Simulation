PImage bg;
int nodos = 0;

boolean simulation = true;
boolean showLabels = false;
boolean finished_simulation = false;

ArrayList<PVector> posiciones = new ArrayList<PVector>();

int p = 4;
int px, py;

PrintWriter output;
BufferedReader routes_reader;

//boolean[][] conexiones;
ArrayList<PVector> conexiones = new ArrayList<PVector>();

// User Defined
int[] entries = {0,3,7,11};

float[] rewards;
float[] distance_to_ap;

class Peaton
{
  int[] ruta;
  color c;
  PVector posicion;
  PVector velocidad;
  int nodo_actual;
  boolean moving;
  boolean finished;
  float m;
  float x;
  float y;
  PVector[] moves;
  int n_moves;
  int it;
  
  Peaton(int[] ruta, color c){
    this.ruta = ruta;
    this.c = c;
    this.posicion = posiciones.get(ruta[0]).copy();
    //arrayCopy(posiciones.get(ruta[0]), this.posicion);
    this.velocidad = new PVector(1.0,1.0);
    this.nodo_actual = 0;
    this.moving = true;
    this.finished = false;
    this.n_moves = 0;
    this.it = 0;
    actualizar_direccion_actual();
  }
  
  void draw(){
    fill(c);
    //fill(0,0,255);
    ellipse(posicion.x, posicion.y, 5,5);
    //stroke(random(255));
    stroke(55);
    line(posicion.x,posicion.y,posicion.x+5,posicion.y+5);
  }
  
  float get_y(float val)
  {
    return m*(val - x) + y;
  }
  
  void actualizar_direccion_actual()
  {
    if(nodo_actual != ruta.length - 1)
    {
      //println("llegue: desde: " + ruta[nodo_actual] + " "+ruta[nodo_actual + 1]);
      PVector p_desde = posiciones.get(ruta[nodo_actual]).copy();
      PVector p_siguiente = posiciones.get(ruta[nodo_actual + 1]).copy();
      
      p_desde.y = height - p_desde.y;
      p_siguiente.y = height - p_siguiente.y;
      
      float x_width = p_desde.x - p_siguiente.x;
      float y_width = p_desde.y - p_siguiente.y;
      
      m = y_width/x_width;
      x = p_desde.x;
      y = p_desde.y;
      //println("m: " + m + " x: "+ x+" y:" + y);
      
      PVector actual = p_desde.copy();
      //println(p_desde.x + " " + p_desde.y);
      //println(p_siguiente.x + " " + p_siguiente.y);
      // add moves
      float factor = random(1,10);
      //float factor = 1.0;
      
      float x_velocity;
      //println("x " + x_width + " y: " + y_width);
      if(abs(x_width) > abs(y_width))
      {
        //n_moves = int(abs(x_width));
        //x_velocity = 1;
        x_velocity = 1./factor;
        n_moves = int(abs(x_width)/x_velocity);
      }
      else
      {
        x_velocity = abs(x_width)/abs(y_width);
        x_velocity = x_velocity/factor;
        n_moves = int(abs(x_width/x_velocity));
      }
      //println("moves: " + n_moves);
      moves = new PVector[n_moves];
      if(actual.x > p_siguiente.x)
      {
        x_velocity *= -1;
      }
      
      //println("x_velocity: " + x_velocity);
      for(int i = 0; i < n_moves; i++)
      {
        float y = get_y(actual.x);
        actual.x += x_velocity;
        actual.y = y;
        //println("move: " + actual.x + " " + actual.y);
        moves[i] = new PVector(actual.x, height - y);
      }
      this.it = 0;
      //println("it " + it + " n_moves" + n_moves);
      //exit();
    }
    else{
      //println("Finished");
      finished = true;
    }
  }
  
  void move(){ 
    
    if(finished)
      return;
      
    if(this.it >= this.n_moves)
    {
      //println("*&*&************************************************");
      nodo_actual += 1;
      actualizar_direccion_actual();
    }
    
    if(finished)
      return;
    
    posicion.x = moves[it].x;
    posicion.y = moves[it].y;
    this.it++;
  }
}

class Ruta
{
  int[] r;
  Ruta(int n)
  {
    r = new int[n];
  }
}

ArrayList<Peaton> peatones;
Ruta[] rutas;

void read_conexiones()
{
  BufferedReader reader = createReader("conexiones.txt");
  String line = null;
  try {
    while ((line = reader.readLine()) != null) {
      String[] pieces = split(line, TAB);
      int i = int(pieces[0]);
      int j = int(pieces[1]);
      conexiones.add(new PVector(i,j));
    }
    reader.close();
  } catch (IOException e) {
    e.printStackTrace();
  }
}

void read_positions()
{
  BufferedReader reader = createReader("positions.txt");
  String line = null;
  try {
    while ((line = reader.readLine()) != null) {
      String[] pieces = split(line, TAB);
      int x = int(pieces[0]);
      int y = int(pieces[1]);
      posiciones.add(new PVector(x,y));
    }
    reader.close();
  } catch (IOException e) {
    e.printStackTrace();
  }
  nodos = posiciones.size();
  read_conexiones();
}

void read_routes()
{
  String line = null;
  try {
    line = routes_reader.readLine();
    
    // no further simulation routes
    if(line == null)
    {
      routes_reader.close();
      finished_simulation = true;
      return;
    }
    
    String[] pieces = split(line, TAB);
    int n_rutas = int(pieces[0]);
    rutas = new Ruta[n_rutas];
    
    for(int i = 0; i < n_rutas; i++)
    {
      line = routes_reader.readLine();
      line = trim(line);
      pieces = split(line, TAB);
      //if(pieces.length == 1)
      //  return;  
      rutas[i] = new Ruta(pieces.length);
      
      for(int j = 0; j < pieces.length; j++)
        rutas[i].r[j] = int(pieces[j]);
    }
  } catch (IOException e) {
    e.printStackTrace();
  }
}

int time = 0;

void setup()
{
  size(517,480);
  bg = loadImage("map.png");
  if(!simulation)
  {
    output = createWriter("positions.txt");
  }
  else
  {
    read_positions();
  }
  stroke(255,0,0);

  peatones = new ArrayList<Peaton>();

  routes_reader = createReader("Simulacion.txt");
  read_routes();
  text("time: "+ time, width-300,100);
  
  for(int i = 0; i < rutas.length; i++)
  {
    //int ridx = int(random(rutas.length));
    peatones.add(new Peaton(rutas[i].r,color(random(255),random(255),random(255))));
    //exit();
  }
}

void draw()
{
  if(finished_simulation)
    noLoop();
  
  // If pedestrian completed its route
  for(int i = 0; i < peatones.size(); i++)
  {
    if(peatones.get(i).finished == true)
    {
        peatones.remove(i);
        //int ridx = int(random(rutas.length));
        //peatones.add(new Peaton(rutas[ridx].r,color(random(255),random(255),random(255))));
        i = i - 1;
    }
  }
  
  //if(peatones.size() < rutas.length - 1)
  if(time % 500 == 0)
  {
    read_routes();
    for(int i = 0; i < rutas.length; i++)
    {
      //int ridx = int(random(rutas.length));
      peatones.add(new Peaton(rutas[i].r,color(random(255),random(255),random(255))));
      //exit();
    }
  }
  
  time += 1;
  
  clear();
  background(bg);
  
  if(showLabels)
  {
    fill(255,0,0);
    for(int i = 0; i < posiciones.size(); i++)
    {
      text("id "+i, posiciones.get(i).x-10,posiciones.get(i).y-10);
    }
  }

  if(simulation)
  {
    stroke(255);
    for(int i = 0; i < conexiones.size(); i++)
    {
      int n1 = int(conexiones.get(i).x);
      int n2 = int(conexiones.get(i).y);
      line(posiciones.get(n1).x,posiciones.get(n1).y,posiciones.get(n2).x,posiciones.get(n2).y);
    }
  }
  
  fill(255,255,0);
  for(int i = 0; i < posiciones.size(); i++)
  {
    ellipse(posiciones.get(i).x,posiciones.get(i).y,10,10);
  }
  
  fill(0,255,255);
  for(int i = 0; i < entries.length; i++)
    ellipse(posiciones.get(entries[i]).x,posiciones.get(entries[i]).y,20,20);  

  for(int i = 0; i < peatones.size(); i++)
  {
    peatones.get(i).draw();
    peatones.get(i).move();
  } 

  fill(255,0,0);
  text("time: "+ int(time/100), width-100,50);
  
  //delay(1);
}

void mouseClicked() {
  if(simulation)
    return;
  px = mouseX;
  py = mouseY;
  nodos += 1;
  posiciones.add(new PVector(px,py));
  output.println(px + "\t" + py);
}

float distance(float x1, float y1, float x2, float y2)
{
  return sqrt(pow(x1-x2,2) + pow(y2-y1,2));
}

void saveDistances()
{
  PrintWriter input;
  input = createWriter("distancias.txt");
  
  /*for(int i = 0; i < conexiones.size(); i++)
  {
    int n1 = int(conexiones.get(i).x);
    int n2 = int(conexiones.get(i).y);
    float d = distance(posiciones.get(n1).x,posiciones.get(n1).y,posiciones.get(n2).x,posiciones.get(n2).y);
    input.println(n1 + "\t" + n2 + "\t" + int(d));
  }*/
  
  for(int i = 0; i < posiciones.size(); i++)
  {
    for(int j = i+1; j < posiciones.size(); j++)
    {
      float d = distance(posiciones.get(i).x,posiciones.get(i).y,posiciones.get(j).x,posiciones.get(j).y);
      input.println(i + "\t" + j + "\t" + int(d));
    }
  }
  
  input.flush();
  input.close();
  println("Distances saved");
}

void saveRewards()
{
  PrintWriter input;
  input = createWriter("recompensas.txt");
  rewards = new float[nodos];
  distance_to_ap = new float[nodos];
  
  int[] attractive_points = {13,5,17,21,19,9};
  
  for(int i = 0; i < posiciones.size(); i++)
  {
    float x = 0.0;
    for(int j = 0; j < attractive_points.length; j++)
    {
      x += distance(posiciones.get(i).x,posiciones.get(i).y,posiciones.get(j).x,posiciones.get(j).y);
    }
    distance_to_ap[i] = x;
    x = x/1000;
    float r = exp(x);
    rewards[i] = r;
    input.println(i + "\t" + r);
  }
  
  // dijsktra for finding attractivness of each route
  
  input.flush();
  input.close();
  println("Rewards saved");  
}

void saveAttractiveness()
{
  PrintWriter input;
  input = createWriter("atractividades.txt");
  
  for(int i = 0; i < posiciones.size(); i++)
  {
    float x1 = distance_to_ap[i];
    
    for(int j = 0; j < posiciones.size(); j++)
    {
      float x2 = distance_to_ap[j];
      float diff_r = rewards[j] - rewards[i];
      float x = sqrt(x1 + x2)*diff_r;
      x = x/1000;
      double a = exp(x);
      println(a);
      input.println(i + "\t" +  j + "\t" + a);
    }
  }
  
  // dijsktra for finding attractivness of each route
  
  input.flush();
  input.close();
  println("Attractiveness saved");
}

void keyPressed()
{
  if(key == ENTER && !simulation)
  {
    output.flush();
    output.close();
    println("saved");
  }
  if(key == 'l')
    showLabels = !showLabels;
  if(key == 'd')
    saveDistances();
  if(key == 'r')
    saveRewards();
  if(key == 'a')
    saveAttractiveness();
}

/*void keyReleased()
{
  if(key == SHIFT)
    showLabels = false;
}*/
