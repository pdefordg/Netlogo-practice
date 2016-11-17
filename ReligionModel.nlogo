;-----VARIABLES
patches-own [
  rationality
  religion
  commitment
  clustering
  
  neighbor-rel-1
  neighbor-rel-2
  neighbor-rel-3
  neighbor-rel-4
  
  neighbor-com-1
  neighbor-com-2
  neighbor-com-3
  neighbor-com-4
]

globals [
  polarization
  cluster-coeff
  total-clustering
  
  simulate-peace
  simulate-unrest
  simulate-controversy
   
  temp-rel-1
  temp-rel-2
  temp-rel-3
  temp-rel-4
  
  temp-com-1
  temp-com-2
  temp-com-3
  temp-com-4
]


;-----SETUP
to setup-random
  clear-all
  
  set simulate-peace 1
  set simulate-unrest 1
  set simulate-controversy 1
  
  ask patches [
    set rationality random-float 1
    set-religion random 4  ; Believers and Practicioners
  ]
  reset-ticks
end

;-----MAIN PROGRAM
to go
  ;movie-start
  
  ; Random rational controversy
  if random-rational-controversy? [
    ifelse random-float 1 > 0.5 [ set rational-controversy rational-controversy + 0.01 ][ set rational-controversy rational-controversy - 0.01 ]
    if rational-controversy > 1 [ set rational-controversy 1 ]
    if rational-controversy < 0 [ set rational-controversy 0 ]
  ]
  ; Random emotional unrest
  if random-emotional-unrest? [
    ifelse random-float 1 > 0.5 [ set emotional-unrest emotional-unrest + 0.01 ][ set emotional-unrest emotional-unrest - 0.01 ]
    if emotional-unrest > 1 [ set emotional-unrest 1 ]
    if emotional-unrest < 0 [ set emotional-unrest 0 ]
  ]
  
  ask patches [ check-neighbors ]
  set total-clustering 0
  ask patches [ flow ]
  ask n-of 1 patches [ set-religion random 4 ]
  set polarization (count patches with [ religion = 0 or religion = 3]) / (count patches)
  set cluster-coeff total-clustering / (count patches)
  
  tick
  if ticks >= 5000 [ stop ] ;; stop after 500 ticks
end


;-----PROCEDURES
to check-neighbors
  ask patch-at  1  0 [ set temp-rel-1 religion set temp-com-1 commitment ]
  set neighbor-rel-1  temp-rel-1
  set neighbor-com-1  temp-com-1
  
  ask patch-at  0  1 [ set temp-rel-2 religion set temp-com-2 commitment ]
  set neighbor-rel-2  temp-rel-2
  set neighbor-com-2  temp-com-2
  
  ask patch-at -1  0 [ set temp-rel-3 religion set temp-com-3 commitment ]
  set neighbor-rel-3  temp-rel-3
  set neighbor-com-3  temp-com-3
  
  ask patch-at  0 -1 [ set temp-rel-4 religion set temp-com-4 commitment ]
  set neighbor-rel-4  temp-rel-4
  set neighbor-com-4  temp-com-4
end

to flow
  ; Interact with neighbour
  interact-neighbor neighbor-rel-1 neighbor-com-1
  interact-neighbor neighbor-rel-2 neighbor-com-2
  interact-neighbor neighbor-rel-3 neighbor-com-3
  interact-neighbor neighbor-rel-4 neighbor-com-4
  
  ; Clustering
  let temp religion
  set clustering count neighbors with [ religion = temp ]
  set total-clustering total-clustering + clustering
end

to interact-neighbor [neighbor-rel neighbor-com ]
  ; Peace dynamics
  if simulate-peace = 1 [
    if religion = 0 and rationality < 0.9 [ set commitment commitment - 0.01 ]
    if religion = 1 [
      if neighbor-rel = 0 [ set commitment commitment - 0.01 ]
      if neighbor-rel = 2 or neighbor-rel = 3 [ set commitment commitment + 0.01 ]
    ]
    if religion = 2 [
      if neighbor-rel = 0 or neighbor-rel = 1 [ set commitment commitment - 0.01 ]
      if neighbor-rel = 3 [ set commitment commitment + 0.01 ]
    ]
    if religion = 3 and rationality < 0.9 [ set commitment commitment - 0.01 ]
  ]

  ; Rational controversy dynamics
  if simulate-controversy = 1 [
    if random-float 10 < rational-controversy [
      if religion = 0 [ set commitment commitment + 0.05 ]
      if religion = 1 and rationality > 0.5 [ set commitment commitment - 0.05 ]
      if religion = 2 and rationality > 0.5 [ set commitment commitment + 0.05 ]
      ;if religion = 3 [ set commitment commitment + 0.05 ] 
    ]
  ]
  
  ; Emotional unrest dynamics
  if simulate-unrest = 1 [
    if random-float 10 < emotional-unrest [
      if religion = 0 [ set commitment commitment + 0.07 ]
      if religion = 1 and rationality < 0.5 [ set commitment commitment + 0.07 ]
      if religion = 2 and rationality < 0.5 [ set commitment commitment + 0.07 ]
      ;if religion = 3 [ set commitment commitment + 0.01 ]
    ]
  ]
  
  ; CONVERSIONS
  ; Go up
  if religion = 0 and commitment <= 0.26 and random-float 1 > 0.5 [ set-religion 1]
  if religion = 1 and commitment >= 0.74 and random-float 1 > 0.5 [ set-religion 2]
  if religion = 2 and commitment >= 0.74 and random-float 1 > 0.5 [ set-religion 3]
  ; Go down
  if religion = 3 and commitment <= 0.26 and random-float 1 > 0.5 [ set-religion 2]
  if religion = 2 and commitment <= 0.26 and random-float 1 > 0.5 [ set-religion 1]
  if religion = 1 and commitment <= 0.26 and random-float 1 > 0.5 [ set-religion 0]
  ; Correct commitment
  if commitment > 1 [ set commitment 1 ]
  if commitment < 0 [ set commitment 0 ]
end

to set-religion [z]
  if z = 0  [           ; Non-believer
    set religion 0
    set pcolor black
  ]
  if z = 1  [           ; Low committed
    set religion 1
    set pcolor yellow
  ]
  if z = 2  [           ; Committed
    set religion 2
    set pcolor orange
  ]
  if z = 3  [           ; Highly committed
    set religion 3
    set pcolor red
  ]
  set commitment 0.5
end
@#$#@#$#@
GRAPHICS-WINDOW
213
26
945
424
-1
-1
11.84
1
10
1
1
1
0
1
1
1
0
60
0
30
1
1
1
Week
10.0

BUTTON
12
26
208
71
NIL
setup-random
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
13
86
107
132
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
115
86
207
132
go-forever
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
11
142
206
175
rational-controversy
rational-controversy
0
1
0
0.025
1
NIL
HORIZONTAL

PLOT
951
26
1316
237
Distribution of religious views vs. time
Time
People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Non-Believers" 1.0 0 -16777216 true "" "plot count patches with [religion = 0 ]"
"Low conviction" 1.0 0 -1184463 true "" "plot count patches with [religion = 1 ]"
"Medium conviction" 1.0 0 -955883 true "" "plot count patches with [religion = 2 ]"
"High conviction" 1.0 0 -2674135 true "" "plot count patches with [religion = 3 ]"

PLOT
952
244
1317
424
Different metrics over time
Time
Metric
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Polarization" 1.0 0 -8431303 true "" "plot polarization"
"Rational controversy" 1.0 0 -5825686 true "" "plot rational-controversy"
"Emotional-unrest" 1.0 0 -13840069 true "" "plot emotional-unrest"

SWITCH
12
180
206
213
random-rational-controversy?
random-rational-controversy?
1
1
-1000

PLOT
12
304
205
424
Clustering
NIL
NIL
0.0
10.0
0.0
8.0
true
false
"" ""
PENS
"Clustering" 1.0 0 -16777216 true "" "plot cluster-coeff"

SLIDER
13
220
205
253
emotional-unrest
emotional-unrest
0
1
0
0.025
1
NIL
HORIZONTAL

SWITCH
15
260
205
293
random-emotional-unrest?
random-emotional-unrest?
1
1
-1000

TEXTBOX
235
450
385
494
Non-believers
24
0.0
0

TEXTBOX
450
437
600
495
Low conviction
24
44.0
1

TEXTBOX
635
437
785
495
Medium conviction
24
25.0
1

TEXTBOX
801
437
915
495
High conviction
24
15.0
1

@#$#@#$#@
## WHAT IS IT?


## HOW IT WORKS


## HOW TO USE IT


## THINGS TO NOTICE


## THINGS TO TRY


## EXTENDING THE MODEL


## NETLOGO FEATURES


## RELATED MODELS


## CREDITS AND REFERENCES


## HOW TO CITE


## COPYRIGHT AND LICENSE
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.0.1
@#$#@#$#@
setup-random repeat 20 [ go ]
@#$#@#$#@
1.0 
    org.nlogo.sdm.gui.AggregateDrawing 2 
        org.nlogo.sdm.gui.ConverterFigure "attributes" "attributes" 1 "FillColor" "Color" 130 188 183 239 145 50 50 
            org.nlogo.sdm.gui.WrappedConverter "" ""   
        org.nlogo.sdm.gui.StockFigure "attributes" "attributes" 1 "FillColor" "Color" 225 225 182 374 157 60 40 
            org.nlogo.sdm.gui.WrappedStock "" "" 0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
