# ===================================================
# ===================  Libraries  ===================
# ===================================================
using JuMP
using Ipopt
# ===================================================
# =================  Solving part  ==================
# ===================================================
#Model variable
m = Model(with_optimizer(Ipopt.Optimizer, print_level=0))

#Main variables

# Volume minimum = 29.8290 hm³, maximium = 37.2350 hm³ // Équivalent à la hauteur de chutte
@variable(m, 29.8290 <= vol <= 37.2350, start=1, base_name="Volume")
# Volume débit total = 217.9259 m³/s, maximium temporaire = 2082 m³/s
@variable(m, 217.9259 <= debTot <=2082, start=1, base_name="Débit total à turbiner")
# Entre 1 et 5 turbine qui fonctionnent en simultanées.
@variable(m, 1 <= nbTurbMarch <= 5, start=0, base_name="Nombre de turbines en marche")


# Boolean numbers of Turbines
@variable(m, 0 <= y1 <= 1, start=0, base_name="1 Turbine fonctionne")
@variable(m, 0 <= y2 <= 1, start=0, base_name="2 Turbines fonctionnent")
@variable(m, 0 <= y3 <= 1, start=0, base_name="3 Turbines fonctionnent")
@variable(m, 0 <= y4 <= 1, start=0, base_name="4 Turbines fonctionnent")
@variable(m, 0 <= y5 <= 1, start=0, base_name="5 Turbines fonctionnent")


# ===================================================
# =================  Constraints   ==================
# ===================================================

@constraint(m, nbTurbineWorking,y1+y2+y3+y4+y5 == 1 )

# Contrainte assez d'eau : 
# minimum de volume = 29.8290
# 𝛿 =36,42,49,56 m³/s pour le jour 1, 2, 3 et 4 
# q = debTot m³/s
# vol = hauteurChuteNettes hm³
# vol+1 = vol - q + 𝛿
# Avec les conversion 𝜓 = 0,0864 pour 1 jour soit 𝜓 = 0.3456 pour 4 jours;

@constraint(m, enoughWater, vol - debTot * 0.0864 + 36 *0.0864 >= 29.8290 )

# ===================================================
# =================  Functions   ==================
# ===================================================

# x représente la hauteur de chute et y le débit turbiné
# Fonction des turbines individuelles : 
function fturb1(x,y)
    p00 =      -233.3
    p10 =       13.44
    p01 =      0.1889
    p20 =     -0.1935
    p11 =    -0.02236
    p02 =    0.005538
    p21 =   0.0004944
    p12 =  -3.527e-05
    p03 =  -1.594e-05
    return p00 + p10*x + p01*y + p20*x^2 + p11*x*y + p02*y^2 + p21*x^2*y + p12*x*y^2 + p03*y^3
end
function fturb2(x,y)
    p00 =      -1.382
    p10 =     0.09969
    p01 =      -1.945
    p20 =   -0.001724
    p11 =     0.09224
    p02 =    0.007721
    p21 =   -0.001096
    p12 =  -6.622e-05
    p03 =  -1.933e-05
    return p00 + p10*x + p01*y + p20*x^2 + p11*x*y + p02*y^2 + p21*x^2*y + p12*x*y^2 + p03*y^3
end

function fturb3(x,y)
    p00 =      -102.4
    p10 =       5.921
    p01 =     -0.5012
    p20 =    -0.08557
    p11 =     0.02467
    p02 =    0.003842
    p21 =  -0.0002079
    p12 =  -2.209e-05
    p03 =  -1.179e-05
    return p00 + p10*x + p01*y + p20*x^2 + p11*x*y + p02*y^2 + p21*x^2*y + p12*x*y^2 + p03*y^3
end

function fturb4(x,y)
    p00 =      -514.8
    p10 =       29.72
    p01 =       2.096
    p20 =     -0.4288
    p11 =     -0.1336
    p02 =    0.005654
    p21 =    0.002048
    p12 =  -5.026e-07
    p03 =  -1.999e-05
    return p00 + p10*x + p01*y + p20*x^2 + p11*x*y + p02*y^2 + p21*x^2*y + p12*x*y^2 + p03*y^3
end
function fturb5(x,y)
    p00 =      -212.1
    p10 =       12.17
    p01 =    0.004397
    p20 =     -0.1746
    p11 =   -0.006808
    p02 =    0.004529
    p21 =   0.0002936
    p12 =  -4.211e-05
    p03 =  -1.176e-05
    return p00 + p10*x + p01*y + p20*x^2 + p11*x*y + p02*y^2 + p21*x^2*y + p12*x*y^2 + p03*y^3
end

# Ajoute tout les résultats à une liste, trie la liste puis retourne la somme des premiers résultats.
function getMaxActiveTurbinePower(_volume,_debitTotal,_NbTurbineWorking)
    listOfAllResults = [fturb1(_volume, _debitTotal), fturb2(_volume, _debitTotal), fturb3(_volume, _debitTotal), fturb4(_volume, _debitTotal), fturb5(_volume, _debitTotal)]
    storedResults = sort(listOfAllResults, rev=true)[1:(round(Int, _NbTurbineWorking))]
    return sum(storedResults)
end


@NLobjective(m, Max, getMaxActiveTurbinePower(vol,debTot,nbTurbMarch))


optimize!(m)

# ===================================================
# =================  DisplayResults   ==================
# ===================================================
status = termination_status(m)

println("Puissance obtenue : ", objective_value(m)," MW")
println("Volume d'eau : $(value.(vol)) hm³")
println("Débit total : $(value.(debTot)) m³/s")
println("Nombre de turbines fonctionnelles: $(value.(nbTurbMarch))")