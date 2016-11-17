;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
extensions [ nw ]

turtles-own [
  role
  link-number
  charge  ;; Charging level
  interactions ;; Quantity of interactions where neighbor tries to convince/infect
  infection-time
  reject?
  immune?
  adoption?
]

globals [
  sized-nodes?
  convincing-maven
  convincing-connector
  convincing-salesman
  convincing-normal
  max-degree
  average-degree
  connector-min-degree
  th
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  ;; Begin
  clear-all
  reset-ticks
  set-default-shape turtles "person"
  set sized-nodes? true
  set convincing-maven 0.75
  set convincing-connector 0.75
  set convincing-salesman 1.00
  set convincing-normal 0.5

  ;; Generate network
  if network-type = "pref-attach" [
    setup-pref-attach-network
    set th 0.4
  ]
  if network-type = "neighbor" [
    setup-neighborhood-network
    set th 0.7
  ]
  if sized-nodes? = true [ resize-nodes ]

  ;; Setup turtle's own variables
  ask turtles [
    set link-number count my-links
  ]

  ;; Network
  set max-degree ( max [count link-neighbors] of turtles )
  show max-degree
  set average-degree mean [ link-number ] of turtles
  show average-degree
  set connector-min-degree ( average-degree + ( (max-degree - average-degree) * th ) )
  show connector-min-degree
  ;let H nw:biggest-maximal-cliques
  ;show H
  ;ask H [ set color orange ]

  ;; Setup turtle's own variables
  ask turtles [
    setup-role ;; Set roles randomly
    set charge 0
    set interactions 0
    set infection-time 0
  ]

  ;; Plots
  update-plots
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Preferential attachment Barabasi
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-pref-attach-network
  make-node nobody        ;; first node, unattached
  make-node turtle 0      ;; second node, attached to first node
  repeat number-of-people - 2 [
    make-node find-partner ;; find partner and use it as attachment
    repeat 1 [ layout ]
  ]
end
to make-node [old-node]
  create-turtles 1
  [
    set color gray
    if old-node != nobody
      [ create-link-with old-node [ set color gray ]
        ;; position the new node near its partner
        move-to old-node
        fd 8
      ]
  ]
end
to-report find-partner
  report [one-of both-ends] of one-of links
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Neighborhood
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-neighborhood-network
  ;; Build population (nodes)
  setup-population
  ;; Build links (social connections)
  let num-links (average-node-degree * number-of-people) / 2 ;undirected network
  while [count links < num-links ] [
    ask one-of turtles [
      let choice ( one-of other turtles in-radius 7 with [not link-neighbor? myself] ) ;; Choose to connect within a radious
      ;let choice ( min-one-of (other turtles with [not link-neighbor? myself]) [distance myself] )
      if choice != nobody [ create-link-with choice ]
    ]
  ]
  ;; Layout: Make people to repulse each other in space, to avoid superposed or clustered people
  repeat 10 [ layout-spring turtles links 0.3 (world-width / (sqrt number-of-people)) 1 ]
end
to setup-population
  create-turtles number-of-people [
    set color white
    setxy (random-xcor * 0.9) (random-ycor * 0.9) ;; Multiply by 0.9 to avoid people near the borders
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup roles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-role
  ;show connector-min-degree
  ifelse count my-links > connector-min-degree [
    set color yellow
    set role "connector"
    set reject? false
    set immune? false
    set adoption? false
  ][
    let M (more-maven * 20)
    let x random 20
    ifelse ( x <= M - 1 ) [ ; Maven
        set color red
        set role "maven"
        set reject? true   ;;; ojoooooo
        set immune? false  ;;; ojoooooooooo
        set adoption? true

        ;; stamp
        let temp color
        set color 136
        set shape "circle"
        stamp
        set shape "person"
        set color temp
    ] [
      let S (more-salesmen * 20)
      let y random 20
        ifelse ( y <= S - 1) [ ; Salesman
          set color orange
          set role "salesman"
          set reject? false
          set immune? false
          set adoption? false
        ] [
          set color blue
          set role "normal"
          set reject? false
          set immune? false
          set adoption? false
        ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mouse select
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to mouse-select
  check-mouse
  display
end
to check-mouse
  if mouse-down? [
    ask turtles-on patch mouse-xcor mouse-ycor [
      if role-select = 1 [
        set color red
        set role "maven"
        set reject? true   ;;; ojoooooo
        set immune? false  ;;; ojoooooooooo
        set adoption? true

        ;; stamp
        let temp color
        set color 136
        set shape "circle"
        stamp
        set shape "person"
        set color temp
      ]
      if role-select = 2 [
        set color yellow
        set role "connector"
        set reject? false
        set immune? false
        set adoption? false
      ]
      if role-select = 3 [
        set color orange
        set role "salesman"
        set reject? false
        set immune? false
        set adoption? false
      ]
      if role-select = 4 [
        set color blue
        set role "normal"
        set reject? false
        set immune? false
        set adoption? false
      ]
    ]
  ]
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; GO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  ask turtles [
    to-recover
    spread-virus
  ]
  tick
  if ticks >= 3000 [ stop ] ;; stop after 300 ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Recover
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to to-recover
  if recover? = true and adoption? = true [
    set infection-time (infection-time + 1)
    if (infection-time >= infect-time) [
      set adoption? false
      ;set reject? false
      ifelse immunity? = true [
        set immune? true
        ;; stamp
        let temp color
        set color 67
        set shape "circle"
        stamp
        set shape "person"
        set color temp
      ][
        set immune? false

        ;; stamp erase
        set shape "circle"
        stamp-erase
        set shape "person"
      ]
      set infection-time 0
      set charge 0
      set interactions 0
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Spread virus
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to spread-virus
  let convincing 0
  if (role = "maven") [ set convincing convincing-maven ]
  if (role = "connector") [ set convincing convincing-connector ]
  if (role = "salesman") [ set convincing convincing-salesman ]
  if (role = "normal") [ set convincing convincing-normal ]
  if (adoption? = true) [
    ask one-of link-neighbors [
      if reject? = false and adoption? =  false and immune? = false [   ;;asignar reject e inmume true más adelante usando globales XXXXXXXXXXXXXXXXXX
        set interactions (interactions + 1)
        ifelse random-float 1 < convincing * stickiness * susceptibility [
          set charge (charge + 1)
          if (charge >= charge-thresh) [
            set adoption? true
            ;; stamp
            let temp color
            set color 136
            set shape "circle"
            stamp
            set shape "person"
            set color temp
          ]
        ] [
          set adoption? false
          if (interactions >= interactions-thresh and cut-interactions? = true) [
            set reject? true
            ;; Set interactions to zero??

            ;; stamp
            let temp color
            set color 97
            set shape "circle"
            stamp
            set shape "person"
            set color temp
          ]
        ]
      ]
    ]
  ]
  ask links [
    ifelse (all? both-ends [ adoption? = true]) [
      set color red
    ] [
      set color grey
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Layout
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Set size of nodes proportional to its degree
to resize-nodes
    ask turtles [ set size (1 + 0.2 * (sqrt count link-neighbors) ) ]
end

; Function taken from a program of Netlogo Models Library
to layout
  ;; the number 3 here is arbitrary; more repetitions slows down the
  ;; model, but too few gives poor layouts
  repeat 3 [
    ;; the more turtles we have to fit into the same amount of space,
    ;; the smaller the inputs to layout-spring we'll need to use
    let factor sqrt count turtles
    ;; numbers here are arbitrarily chosen for pleasing appearance
    layout-spring turtles links (1 / factor) (7 / factor) (1 / factor)
    display  ;; for smooth animation
  ]
  ;; don't bump the edges of the world
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  ;; big jumps look funny, so only adjust a little each time
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ask turtles [ setxy (xcor - x-offset / 2) (ycor - y-offset / 2) ]
end
to-report limit-magnitude [number limit]
  if number > limit [ report limit ]
  if number < (- limit) [ report (- limit) ]
  report number
end
@#$#@#$#@
GRAPHICS-WINDOW
370
10
1017
470
24
16
13.0
1
14
1
1
1
0
0
0
1
-24
24
-16
16
1
1
1
Time
30.0

SLIDER
24
149
152
182
number-of-people
number-of-people
5
300
150
5
1
NIL
HORIZONTAL

BUTTON
83
37
147
70
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
218
103
361
136
average-node-degree
average-node-degree
1
20
6
1
1
NIL
HORIZONTAL

BUTTON
151
37
214
70
Go
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

BUTTON
217
37
294
70
Go once
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

SLIDER
25
297
129
330
stickiness
stickiness
0
1
1
0.1
1
NIL
HORIZONTAL

CHOOSER
24
102
162
147
network-type
network-type
"pref-attach" "neighbor"
0

PLOT
1023
170
1337
311
Degree distribution
Degree
Nodes
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [count link-neighbors] of turtles"

PLOT
1024
316
1335
470
log-log degree distribution
log(degree)
log(# of nodes)
0.0
0.3
0.0
0.3
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ";; for this plot, the axes are logarithmic, so we can't\n;; use \"histogram-from\"; we have to plot the points\n;; ourselves one at a time\nplot-pen-reset  ;; erase what we plotted before\n;; the way we create the network there is never a zero degree node,\n;; so start plotting at degree one\nlet degree 1\nwhile [degree <= 30] [\n  let matches turtles with [count link-neighbors = degree]\n  if any? matches\n    [ plotxy log degree 10\n             log (count matches) 10 ]\n  set degree degree + 1\n]"

PLOT
1022
10
1336
166
Percentage adopters/infected
Time
Adopters
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if (count turtles >= 1) [\n  plot (count turtles with [ adoption? = true ] / count turtles )\n]"

SWITCH
25
333
139
366
recover?
recover?
0
1
-1000

SLIDER
24
185
137
218
more-maven
more-maven
0
1
0.05
0.05
1
NIL
HORIZONTAL

SLIDER
140
185
261
218
more-salesmen
more-salesmen
0
1
0.1
0.05
1
NIL
HORIZONTAL

SLIDER
132
297
235
330
susceptibility
susceptibility
0
1
1
0.1
1
NIL
HORIZONTAL

SWITCH
234
333
344
366
immunity?
immunity?
0
1
-1000

SLIDER
141
333
233
366
infect-time
infect-time
0
100
30
5
1
NIL
HORIZONTAL

SLIDER
25
369
147
402
charge-thresh
charge-thresh
1
6
3
1
1
NIL
HORIZONTAL

SLIDER
157
405
279
438
interactions-thresh
interactions-thresh
1
10
10
1
1
NIL
HORIZONTAL

SWITCH
25
405
154
438
cut-interactions?
cut-interactions?
1
1
-1000

BUTTON
24
222
128
255
Mouse-select
mouse-select
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
131
222
246
255
role-select
role-select
1
4
3
1
1
NIL
HORIZONTAL

TEXTBOX
220
139
357
157
*Just for neigh. network
9
0.0
1

TEXTBOX
142
85
292
103
Network settings
11
0.0
1

TEXTBOX
134
277
284
295
Social epidemic settings
11
0.0
1

TEXTBOX
249
224
399
268
1. Maven\n2. Connector\n3. Salesman\n4. Normal
9
0.0
1

TEXTBOX
172
13
223
31
Control
11
0.0
1

TEXTBOX
372
474
440
494
Mavens
16
15.0
1

TEXTBOX
434
474
521
494
Connectors
16
43.0
1

TEXTBOX
531
474
601
494
Salesman
16
25.0
1

TEXTBOX
608
475
666
495
Normal
16
105.0
1

TEXTBOX
751
475
901
495
Infected/Adopters
16
134.0
1

TEXTBOX
889
475
959
495
Immune
16
84.0
1

TEXTBOX
962
475
1017
495
Reject
16
94.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
