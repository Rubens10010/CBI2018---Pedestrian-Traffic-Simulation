from random import *
import copy
from math import *
import sys
import numpy as np

# Ant colony system(AS)
# Author: Ruben Edwin Hualla Quispe

### Parametros ###
n_nodos = 22

p = 0.99
a = 1.
b = 1.
Q = 1.
q0 = 0.7
w = 0.05

feromona_inicial = 0.1
n_hormigas = 100
n_iteraciones = 10

nodo_inicial = 3
nodos_finales = [5,17,21]

nodos_salida = [0,3,7,11]

def cargar_matriz_distancias():
	distancias = np.zeros((n_nodos,n_nodos))
	ifile = open("distancias.txt", "r")
	for line in ifile:
		line = line.strip()
		values = line.split("\t")
		idx1 = int(values[0])
		idx2 = int(values[1])
		d = float(values[2])
		distancias[idx1][idx2] = d
		distancias[idx2][idx1] = d
	return distancias

def cargar_matriz_atractividades():
	atractividades = np.zeros((n_nodos,n_nodos))
	ifile = open("atractividades.txt", "r")
	for line in ifile:
		line = line.strip()
		values = line.split("\t")
		idx1 = int(values[0])
		idx2 = int(values[1])
		d = float(values[2])
		atractividades[idx1][idx2] = d
	return atractividades

def cargar_matriz_conexiones():
	conexiones = np.full((n_nodos,n_nodos),False,dtype=bool)
	ifile = open("conexiones.txt", "r")
	for line in ifile:
		line = line.strip()
		values = line.split("\t")
		idx1 = int(values[0])
		idx2 = int(values[1])
		conexiones[idx1][idx2] = True
		conexiones[idx2][idx1] = True
	return conexiones

def cargar_recompensas_nodo():
	recompensas = list()
	ifile = open("recompensas.txt","r")
	for line in ifile:
		line = line.strip()
		values = line.split("\t")
		idx = int(values[0])
		r = float(values[1])
		recompensas.append(r)
	return np.array(recompensas)

def crear_matriz_visibilidad(distancias):
	visibilidades = copy.deepcopy(distancias)
	#visibilidades = flujos*distancias
	visibilidades = np.where(visibilidades != 0.0, 1./visibilidades, visibilidades)
	return visibilidades

def crear_matriz_feromonas():
	feromonas = np.full((n_nodos, n_nodos), feromona_inicial)
	feromonas[np.diag_indices(n_nodos)] = 0.
	return feromonas

def get_costo(camino):
	cost = sum([distancias[camino[i]][camino[i + 1]] for i in range(len(camino) - 1)])
	reward = sum([recompensas[camino[i]] + recompensas[camino[i+1]] for i in range(len(camino) - 1)])
	costo = cost/reward
	return costo

def siguiente_nodo(nodo_actual, camino, feromonas):
	# ciudades por visitar
	nodos_alcanzables = [i for i in range(n_nodos) if conexiones[nodo_actual][i] == True]
	indices = [i for i in nodos_alcanzables if i not in camino]
	wanderer = True

	if len(indices) == 0:
		#print "Error! there're not enough possible paths available"
		#print "camino"
		#print camino
		return (-1,wanderer)
		#exit(0)
	
	wanderer = False
	if len(indices) == 1:
		return (indices[0],wanderer)

	v = visibilidades[nodo_actual][indices]
	f = feromonas[nodo_actual][indices]

	q = random()
	if q >= q0:
		f = f**a
		b = atractividades[nodo_actual][indices]
		v = np.array([v[i]**b[i] for i in range(len(indices))])
		
		#v = v**b
		
		suma = np.dot(v, f)
		p = [v[i]*f[i]/suma if suma > 0.0 or suma < 0.0 else 0.0 for i in range(len(v))]

		"""if float(suma) is not 0:
			print "no here"
			p = (v*f)/suma
		else:
			print "reach here"
			p = [0. for pr in p]"""

		prob_seleccion = random()
		#print prob_seleccion
		curr = p[0]
		j = 0
		for i in indices:
			prob_seleccion -= p[j]
			if prob_seleccion <= 0:
				return (i,wanderer)
			j += 1
	else:
		z = v*f
		i = (-z).argsort()
		#print i
		i = indices[i[0]]
		return (i,wanderer)

def get_camino(hormiga_index, nodo_inicial, feromonas):
	camino = list()
	camino.append(nodo_inicial)
	nodo_actual = nodo_inicial
	while nodo_actual not in nodos_finales:
		(nodo_actual,wanderer) = siguiente_nodo(nodo_actual,camino,feromonas)
		if not wanderer:
			camino.append(nodo_actual)
		else:
			return camino
	return camino

def get_camino_salida(hormiga_index, nodo_inicial, camino, feromonas):
	nodo_actual = nodo_inicial
	while nodo_actual not in nodos_salida:
		(nodo_actual,wanderer) = siguiente_nodo(nodo_actual,camino,feromonas)
		if not wanderer:
			camino.append(nodo_actual)
		else:
			return camino
	return camino

def mandar_hormigas(caminos, n, n_inicial, mejor_hormiga_global, mejor_costo_global, mejor_camino_global, feromonas):
	costos = list()
	caminos = list()
	arcos_caminos = list()
	for i in range(n):	# hormigas
		#c = get_camino(i, randint(0,n_ciudades - 1))
		c = get_camino(i, n_inicial, feromonas)
		caminos.append(c)
		arcos = [(c[i],c[i+1]) for i in range(len(c) - 1)]
		arcos_caminos.append(arcos)
		cost = get_costo(c)
		costos.append(cost)
		# update online
		for (c1,c2) in arcos:
			feromonas[c1][c2] = (1-w)*feromonas[c1][c2] + w*feromona_inicial
		
	mejor_hormiga = np.argsort(np.array(costos))[0]	
	mejor_camino = [i for i in caminos[mejor_hormiga]]
	mejor_camino = arcos_caminos[mejor_hormiga]
	
	if mejor_costo_global > costos[mejor_hormiga]:
		mejor_hormiga_global = mejor_hormiga
		mejor_costo_global = costos[mejor_hormiga]
		mejor_camino_global = mejor_camino
		#print "best global {} cost: {}".format(mejor_camino_global, mejor_costo_global)

	#Actualizar feromonas	
	for i in range(n_nodos):
		for j in range(n_nodos):
			feromonas[i][j] = feromonas[i][j]*(p)	#evaporacion
			if (i,j) in mejor_camino_global:
				feromonas[i][j] += (1-p)*(1./mejor_costo_global)
	#print feromonas
	#return caminos[mejor_hormiga]
	return (feromonas,mejor_hormiga_global,mejor_costo_global,mejor_camino_global)

def mandar_hormigas_no_update(n, n_inicial, feromonas):
	costos = list()
	caminos = list()
	#arcos_caminos = list()
	for i in range(n):	# hormigas
		#c = get_camino(i, randint(0,n_ciudades - 1))
		c1 = get_camino(i, n_inicial, feromonas)
		c2 = get_camino_salida(i, c1[-1], c1, feromonas)
		c = c2
		caminos.append(c)
		#arcos = [(c[i],c[i+1]) for i in range(len(c) - 1)]
		#arcos_caminos.append(arcos)
		cost = get_costo(c)
		costos.append(cost)
	return (caminos, costos)

def save_n_iterations_to_file(n, file_name):
	ofile = open(file_name, "w")

	entries = [0,3,7,11]	# per hour
	n_people = [5,9,15,11]
	total_people = sum(n_people)

	#entries = [nodo_inicial]
	#n_people = [50]

	#n_hormigas = random(100,)
	# numero de simulaciones, tiempo
	feromonas_list = [crear_matriz_feromonas() for e in entries]

	rutas = list()
	costos = list()

	for j in range(len(feromonas_list)):
		mejor_hormiga_global = -1
		mejor_costo_global = 10000
		mejor_camino_global = list()
		for i in range(n_iteraciones):
			(feromonas_list[j], mejor_hormiga_global,mejor_costo_global,mejor_camino_global) = mandar_hormigas(rutas, n_hormigas, entries[j], mejor_hormiga_global,mejor_costo_global,mejor_camino_global, feromonas_list[j])

	print "Models done!"

	for iteration in range(n):
		ofile.write(str(total_people)+"\n")
		routes = list()
		for i in range(len(entries)):
			(caminos, costos) = mandar_hormigas_no_update(n_people[i], entries[i], feromonas_list[i])
			#ofile.write(str(n_people[i]) + "\n")
			routes += caminos
		for l in routes:
			for v in l:
				ofile.write(str(v)+"\t");
			ofile.write("\n")
	print "Routes Saved"			

distancias = cargar_matriz_distancias()
atractividades = cargar_matriz_atractividades()
conexiones = cargar_matriz_conexiones()
recompensas = cargar_recompensas_nodo()
visibilidades = crear_matriz_visibilidad(distancias)
#feromonas = crear_matriz_feromonas()

"""
print distancias
print visibilidades
print feromonas
print conexiones
print recompensas"""

# Algoritmo
"""
rutas = list()
costos = list()

mejor_hormiga_global = -1
mejor_costo_global = 10000
mejor_camino_global = list()

for i in range(n_iteraciones):
	(rutas,costos,mejor_hormiga_global,mejor_costo_global,mejor_camino_global) = mandar_hormigas(rutas, n_hormigas,0, mejor_hormiga_global,mejor_costo_global,mejor_camino_global)

print "best global {} cost: {}".format(mejor_camino_global, mejor_costo_global)"""

#print feromonas

save_n_iterations_to_file(10, "Simulacion.txt")

#print "Rutas:"
#for i in range(len(rutas)):
#	print "Ruta: {} Costo: {}".format(rutas[i],costos[i])
