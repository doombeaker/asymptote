# Asymptote Drawing

## Description
Generate precise, publication-quality vector graphics using the Asymptote (asy) language. Asymptote excels at any diagram requiring mathematical precision and logical construction: geometric proofs, flowcharts, scientific plots, circuit diagrams, Feynman diagrams, fractals, data visualizations, and technical illustrations. LaTeX labels are natively supported for professional typesetting. This skill emphasizes exact construction over manual approximation, ensuring all geometric relationships, alignments, and proportions are mathematically faithful.

## Trigger Phrases
- "asy 绘图"
- "asymptote 绘图"
- "用 asy 画"
- "画几何图"
- "画流程图"
- "科学绘图"
- "画函数图像"
- "画示意图"
- "画电路图"
- "画费曼图"
- "vector graphics"
- "asymptote diagram"
- "draw with asy"
- "精确绘图"
- "技术插图"

## Instructions

You are an expert in the Asymptote vector graphics language. When given a diagram description, you must output complete, compilable Asymptote code that faithfully represents all stated constraints. Asymptote is a C++-like programming language for technical drawing — treat it as code, not as a drawing API.

### Core Philosophy: Construction Over Approximation
Never guess coordinates. Every point must be derived from geometric relationships using exact constructions. If the description says "CD perpendicular to AB", construct the perpendicular using `extension()`, `intersectionpoint()`, or the `geometry` module — never place point D by eye.

### Language Convention: English Labels by Default
**All output diagrams MUST use English labels by default.** The Asymptote + LaTeX compilation pipeline in this environment does not support CJK (Chinese/Japanese/Korean) font rendering. Chinese characters will appear as blank boxes or trigger compilation failures. If a user explicitly requests another language, add a warning that the result may not render correctly.

### Basic Setup
```asy
size(10cm, 0);                  // Width 10cm, height auto-scales
// OR
unitsize(1cm);                  // 1 unit = 1cm
// OR
size(200, 200, IgnoreAspect);   // Fixed pixel dimensions

import geometry;                // Advanced geometry (optional but common)
settings.tex = "pdflatex";      // Use pdflatex for labels
```

### Naming and Parameterization
**Never scatter raw numbers throughout your code.** Asymptote is a programming language — use variables to make your diagrams maintainable, readable, and easy to adjust.

**Anti-pattern (hard to read, easy to break):**
```asy
// BAD: magic numbers everywhere
boxLabel((-6, 8.5), "Prep", gray, 3.0, 0.7);
boxLabel((-6, 7.4), "Wash", blue, 3.0, 0.7);
boxLabel((-6, 6.3), "Chop", purple, 3.0, 0.7);
arrPath((-6,8.15)--(-6,7.75));
arrPath((-4.5,6.3)--(-1.5,6.3));
```

**Good practice (parameterized):**
```asy
// GOOD: named constants, single source of truth
real xPrep  = -6;      // column positions
real xCook  = 0;
real xFinish = 6;
real yTop   = 8.5;     // top row y-coordinate
real dy     = 1.1;     // vertical spacing between boxes
real bw     = 3.0;     // box width
real bh     = 0.7;     // box height

boxLabel((xPrep, yTop),      "Prep",  gray,  bw, bh);
boxLabel((xPrep, yTop-dy),   "Wash",  blue,  bw, bh);
boxLabel((xPrep, yTop-2*dy), "Chop",  purple, bw, bh);

arrPath((xPrep, yTop-bh/2-0.05)--(xPrep, yTop-dy+bh/2+0.05));
arrPath((xPrep+bw/2, yTop-2*dy)--(xCook-bw/2, yTop-2*dy));
```

**Benefits:**
- Change `dy = 1.1` to `dy = 1.3` → entire diagram spreads out automatically
- Change `xCook = 0` to `xCook = 1` → entire column shifts
- No risk of forgetting to update a scattered coordinate
- Self-documenting: `xPrep` tells you what it is, `-6` does not

**Rule of thumb:** If a number appears more than once, make it a variable. If a coordinate has semantic meaning (e.g., "column 2", "top row"), give it a name.

**Also parameterize repeated offsets:**
When many labels or annotations share the same vertical/horizontal offset from a base coordinate, extract that offset too. It makes the layout intent explicit and keeps rows/columns perfectly aligned.

```asy
// BAD: magic offsets scattered everywhere
label("1. Send",    (pUser.x,  yBot - 2.5), fontsize(8pt));
label("2. Auth",    (pSCX.x,   yBot - 2.5), fontsize(8pt));
label("3. Route",   (pCGR.x,   yBot - 2.5), fontsize(8pt));
label("Web Canvas", (pUser.x,  yTop + 2.2), fontsize(8pt));
label("Frontend",   (pUser.x,  yTop + 1.8), fontsize(7pt));

// GOOD: one named variable per alignment row
real ySteps      = yBot - 2.5;
real yAnnTop     = yTop + 2.2;
real yAnnSub     = yTop + 1.8;

label("1. Send",    (pUser.x, ySteps),  fontsize(8pt));
label("2. Auth",    (pSCX.x,  ySteps),  fontsize(8pt));
label("3. Route",   (pCGR.x,  ySteps),  fontsize(8pt));
label("Web Canvas", (pUser.x, yAnnTop), fontsize(8pt));
label("Frontend",   (pUser.x, yAnnSub), fontsize(7pt));
```

### Store Visual Elements as Named Variables

Just like coordinates, **paths, pens, and pictures should be stored as variables**. Asymptote is a programming language — treat it like one. Inline paths and anonymous pens are hard to read, hard to debug, and hard to modify.

**Anti-pattern (inline everything):**
```asy
// BAD: complex path hidden inside draw(), pen hidden in fill()
draw((0,0)--(2,0)--(2,1)--(1,1.5)--cycle, red+linewidth(1.2pt));
fill(circle((3,0.5), 0.8), rgb(0.9,0.95,1.0));
```

**Good practice (named variables):**
```asy
// GOOD: every visual element has a name
path house = (0,0)--(2,0)--(2,1)--(1,1.5)--cycle;
path window = circle((3,0.5), 0.8);
pen wallPen = red + linewidth(1.2pt);
pen glassFill = rgb(0.9, 0.95, 1.0);

draw(house, wallPen);
fill(window, glassFill);
```

**Why this matters:**
- **Readability**: `wallPen` tells you what it is; `red+linewidth(1.2pt)` does not.
- **Debuggability**: If the color is wrong, you know exactly which variable to change.
- **Reusability**: The same pen or path can be reused across multiple elements without copy-pasting.
- **Refactoring**: Want to make all dashed lines dotted? Change one `pen` definition, not every `draw()` call.

**Rule of thumb:** If a path is used more than once, or a pen controls more than one element, give it a name. If a path is complex (more than 3 segments), give it a name even if used once.

### Drawing Primitives
```asy
// Points and paths
pair A = (0, 0);
draw(A--B);                     // Line segment
draw(A--B--C--cycle);           // Polygon
draw(circle(O, r));             // Circle
draw(arc(O, r, a1, a2));        // Arc (angles in degrees, CCW)

// Dots and labels
dot(A);                         // Dot
dot("$A$", A, NE);              // Dot with LaTeX label, aligned NE
label("$x$", pos, align);       // Label at position

// Fills
fill(path, color);              // Fill region
filldraw(path, fillpen, drawpen); // Fill + draw boundary

// Pens (colors and styles)
pen redpen = red + linewidth(1.0) + dashed;
pen bluepen = blue + dotted;
// Colors: black, red, blue, green, magenta, cyan, yellow, white, gray(0.5)
// Styles: solid, dashed, dotted, dashdotted
// Width: linewidth(size) where size is in bp (1bp = 1/72 inch)
```

### Path Construction Operators
- `A--B` : straight line segment
- `A..B` : smooth Bezier curve
- `A::B` : inflection-free curve (`..tension atleast 1..`)
- `A---B` : very straight (`..tension atleast infinity..`)
- `cycle` : close path smoothly
- `^^` : concatenate paths (move pen without drawing)

### Coordinate System & Directions
- `pair` is the 2D point type: `(x, y)`
- Compass directions: `N=(0,1)`, `S=(0,-1)`, `E=(1,0)`, `W=(-1,0)`, `NE=unit(N+E)`, etc.
- `dir(angle)` : unit vector at `angle` degrees from x-axis
- `I` = `(0,1)`; multiplying by `I` rotates 90 degrees counterclockwise
- Complex arithmetic works: `A + r*dir(60)` places a point at distance `r` and angle 60 degrees

---

## Domain-Specific Techniques

### 1. Geometry Diagrams

**Exact Constructions — NEVER approximate:**
```asy
// Intersection of two lines
pair P = extension(A, B, C, D);

// Intersection of two paths
pair P = intersectionpoint(path1, path2);
pair[] all = intersections(path1, path2);

// Foot of perpendicular from P to line AB
pair D = extension(P, P + I*dir(A--B), A, B);

// Midpoint
pair M = 0.5*(A + B);

// Parallel line through C
pair E = extension(C, C + (B-A), F, G);

// Perpendicular bisector intersection (circumcenter)
pair O = extension(
    midpoint(A--B), midpoint(A--B) + I*dir(A--B),
    midpoint(B--C), midpoint(B--C) + I*dir(B--C)
);
```

**Right Angle Marks (`perpendicular`):**
The second argument to `perpendicular()` is the **offset direction** — it must point into the angle's interior, bisecting the two rays.
```asy
// CORRECT: the mark sits between the two segments
perpendicular(D, NE, D--C, blue);           // Angle opens NE
perpendicular(F, NE, F--E, blue);           // Between FB and FE
perpendicular(G, unit(dir(G--E)+dir(G--O)), G--E, red); // Bisector of angle EGO
```
If the symbol appears on the wrong side or outside the angle, adjust the direction to the interior bisector.

### 2. Flowcharts

**Design Principle: Keywords Inside, Details Outside**

Flowchart boxes should contain **only keywords or short phrases** (1-3 words). Do not stuff boxes with full sentences or paragraphs. Detailed explanations belong in:
- Separate annotation labels near the box
- A legend or sidebar
- Footnotes below the diagram

**Preferred approach — manual boxes with external annotations:**
```asy
unitsize(1cm);

// Helper to draw a labeled box
void boxLabel(pair c, string[] lines, pen fillpen, real w, real h) {
    pair bl = c + (-w/2, -h/2);
    pair tr = c + (w/2, h/2);
    fill(box(bl, tr), fillpen);
    draw(box(bl, tr), black+1pt);
    real dy = 0.40;
    real y0 = c.y + (lines.length-1)*dy/2;
    for (int i=0; i<lines.length; ++i)
        label(lines[i], (c.x, y0-i*dy), fontsize(8pt));
}

void arr(pair a, pair b) { draw(a--b, arrow=Arrow(TeXHead)); }

// --- Flowchart elements (keywords only) ---
boxLabel((0,4), new string[]{"Start"}, gray, 2.5, 0.8);
boxLabel((0,2.5), new string[]{"Input x"}, rgb(0.9,0.9,1.0), 2.5, 0.8);
boxLabel((0,0.5), new string[]{"x > 0?"}, rgb(1.0,0.9,0.8), 2.5, 0.8);
boxLabel((-3.5,-1.5), new string[]{"Output"}, rgb(0.9,1.0,0.9), 2.2, 0.8);
boxLabel((3.5,-1.5), new string[]{"Output"}, rgb(1.0,0.9,0.9), 2.2, 0.8);
boxLabel((0,-3.5), new string[]{"End"}, gray, 2.5, 0.8);

// --- Annotations (detailed explanations outside boxes) ---
label("{\\small Positive}", (-3.5, -2.5), fontsize(8pt));
label("{\\small Non-positive}", (3.5, -2.5), fontsize(8pt));

// --- Arrows ---
arr((0,3.6), (0,2.9));
arr((0,2.1), (0,0.9));
arr((-0.9,0.1), (-2.3,-1.1));
arr((0.9,0.1), (2.3,-1.1));
arr((-2.3,-1.9), (-1.2,-3.1));
arr((2.3,-1.9), (1.2,-3.1));
```

**Why this design:**
- Boxes stay compact and readable at any zoom level
- The diagram remains scannable — keywords jump out
- Detailed explanations live where they don't clutter the flow
- Easy to localize (change annotations without moving boxes)

**Connector Paths: Straight vs Curved**

Avoid cluttering the diagram with straight lines that pass too close to unrelated boxes. Choose the path operator based on the geometric relationship:

| Situation | Operator | Example |
|---|---|---|
| Direct vertical/horizontal flow, no obstacles | `A--B` | Sequential steps in a column |
| Need to route around a box | `A..B` | Smooth curve avoiding overlap |
| Want a graceful arc with intuitive direction | `A{dir}..{dir}B` | Direction specifiers (preferred over raw controls) |
| Need exact control points (rarely needed) | `A..controls C and D..B` | Exact spline with two control points |
| Stepwise bend (orthogonal) | `A--C--B` | Right-angle connector via waypoint |

**Rule of thumb:** If a straight arrow would pass within 0.5 units of an unrelated box, use a curve or an intermediate waypoint.

```asy
// Straight: fine for clear vertical/horizontal gaps
arr((0,3), (0,2));

// Curve: avoids intermediate boxes
arr((-2,1)..(-1,0)..(0,-1));

// Graceful arc with direction specifiers — human-friendly and readable
// {S} = outgoing/incoming tangent points South (down)
draw(cgrOut{S}..{S}nodeIn, arrow=Arrow(TeXHead));

// {E} = tangent points East (right); produces a smooth outward arc
draw(comfyOut{E}..{E}resultIn, arrow=Arrow(TeXHead));

// Exact control points — only when you truly need pixel-precise routing
path loop = (3,0)..controls (3,2) and (1,2)..(1,0);
draw(loop, arrow=Arrow(TeXHead));

// Waypoint: orthogonal routing (down then right)
arr((0,0)--(0,-1)--(2,-1));
```

**Why prefer `{dir}` over `controls`:**
- `{S}` says "curve downward" — the intent is obvious.
- `..controls (x1,y1) and (x2,y2)..` says "here are two magic numbers" — hard to read and adjust.
- Direction specifiers use the same compass directions (`N`, `S`, `E`, `W`, `up`, `down`, `left`, `right`) already used for label alignment, so there is no new concept to learn.

**Anti-pattern to avoid:** Do not draw long diagonal straight lines across the entire diagram — they create visual noise and are hard to follow. Break them into segments or use curves.

### 3. Scientific Plots (graph module)

```asy
import graph;

size(10cm, 8cm, IgnoreAspect);

real f(real x) { return sin(x); }
draw(graph(f, 0, 2pi), red);

xaxis("$x$", arrow=Arrow);
yaxis("$y$", arrow=Arrow);
```

### 4. Feynman Diagrams

```asy
import feynman;
fmdefaults();

drawFermion(xu--zu--yu);
drawGluon(arc(center, a, b, CW));
drawVertexOX(zu);
```

### 5. Technical Diagrams (CAD, circuits, annotations)

```asy
import CAD;           // CAD-style dimensioning
import annotate;      // PDF annotations
import labelpath;     // Labels along curved paths
```

---

## The `geometry` Module

For advanced geometry, `import geometry;` provides structures:
```asy
point A = point((0,0));
line l = line(A, B);
circle c = circle(O, r);
triangle t = triangle(A, B, C);
```

However, for most diagrams, explicit `pair` + `extension()` constructions are clearer and more predictable.

---

## Step-by-Step Construction Protocol

1. **Identify all points** mentioned or implied.
2. **Establish a coordinate framework**: Choose one convenient base (e.g., O at origin, AB on x-axis). This is your only "free" choice.
3. **Construct points in dependency order**:
   - Independent points first
   - Intersection points (`extension`, `intersectionpoint`)
   - Perpendicular/parallel projections
   - Points on circles/arcs
4. **Draw elements**: Background to foreground.
5. **Add markings**: Right angles, tick marks, angle arcs.
6. **Add labels**: Use LaTeX math mode for symbols. **Default to English** for all text labels.
7. **Set size and compile**.

---

## Common Templates

**Semicircle with Diameter AB:**
```asy
pair A = (-2, 0), B = (2, 0), O = 0.5*(A+B);
draw(A--B);
draw(arc(O, abs(B-O), 0, 180));
dot("$O$", O, S);
```

**Right Triangle with Altitude:**
```asy
pair A = (0, 0), B = (4, 0), C = (0, 3);
pair D = extension(A, A + I*dir(B--C), B, C);
draw(A--B--C--cycle);
draw(A--D, dashed);
perpendicular(D, NE, D--A, blue);
```

**Two Circles Intersecting:**
```asy
pair O1 = (-1, 0), O2 = (1, 0);
path c1 = circle(O1, 1.5), c2 = circle(O2, 1.5);
pair[] ips = intersections(c1, c2);
draw(c1); draw(c2);
draw(ips[0]--ips[1]);  // Common chord
```

**Sierpinski Triangle (Fractal):**
```asy
void Sierpinski(pair A, real s, int q, bool top=true) {
  pair B = A - (1, sqrt(2))*s/2;
  pair C = B + s;
  if(top) fill(A--B--C--cycle);
  unfill((A+B)/2--(B+C)/2--(A+C)/2--cycle);
  if(q > 0) {
    Sierpinski(A, s/2, q-1, false);
    Sierpinski((A+B)/2, s/2, q-1, false);
    Sierpinski((A+C)/2, s/2, q-1, false);
  }
}
```

---

## Compilation

```bash
asy -f pdf filename.asy       // Generate PDF
asy -f svg filename.asy       // Generate SVG
asy -f png filename.asy       // Generate PNG
asy -V filename.asy           // Compile and open viewer
```

---

## Critical Rules
- **Never approximate**: Compute exact positions via geometry, not eyeballing.
- **Document free choices**: Comment angles or lengths you chose arbitrarily.
- **Use `extension()` for lines**, `intersectionpoint()` for paths — know the difference.
- **Right angle marks**: Direction must bisect the angle interior; use `unit(dir(G--E)+dir(G--O))` when uncertain.
- **Always label points**: `dot("$A$", A, dir)` not just `dot(A)`.
- **Set appropriate size**: `size()` ensures the diagram scales well.
- **Ensure valid code**: Output must compile with `asy -f pdf file.asy`.
- **Avoid 3D unless requested**: Don't use `three`, `graph3`, `solids` unless explicitly asked.
- **English labels by default**: CJK characters will not render correctly in this environment. Use English for all labels unless the user explicitly requests otherwise and accepts the rendering risk.
- **Flowchart boxes contain keywords only**: Never put full sentences inside flowchart elements. Use external annotations or sidebars for detailed explanations.

## Examples

### Example 1: Semicircle geometry
**User**: O is the center of a semicircle. C and E are points on the arc. CD is perpendicular to AB, EF is perpendicular to AB, EG is perpendicular to CO. CD is on the left, EF is on the right.

```asy
size(10cm, 0);
import geometry;

pair O = (0, 0);
real r = 2.5;
pair A = (-r, 0), B = (r, 0);

draw(A--B);
draw(arc(O, r, 0, 180));

// C on left (angle > 90), E on right (angle < 90)
real angleC = 120, angleE = 60;
pair C = O + r*dir(angleC);
pair E = O + r*dir(angleE);

pair D = (C.x, 0);    // CD perpendicular to AB
pair F = (E.x, 0);    // EF perpendicular to AB
pair G = extension(E, E + I*dir(angleC), C, O);  // EG perpendicular to CO

draw(O--C); draw(O--E);
draw(C--D, dashed+blue);
draw(E--F, dashed+blue);
draw(E--G, dashed+red);

perpendicular(D, NE, D--C, blue);
perpendicular(F, NE, F--E, blue);
perpendicular(G, unit(dir(G--E)+dir(G--O)), G--E, red);

dot("$O$", O, S); dot("$A$", A, SW); dot("$B$", B, SE);
dot("$C$", C, NW); dot("$E$", E, NE);
dot("$D$", D, S); dot("$F$", F, S); dot("$G$", G, NW);
```

### Example 2: Flowchart (keywords + external annotations)
**User**: Draw a flowchart: Start -> Input x -> Check if x>0 -> Yes: output positive; No: output non-positive -> End

```asy
unitsize(1.2cm);

// --- Parameters (single source of truth) ---
real xc      = 0;        // center column x
real xLeft   = -3.5;     // left output column
real xRight  = 3.5;      // right output column
real yTop    = 5;        // topmost box y
real dy      = 1.5;      // vertical spacing
real bw      = 2.5;      // box width
real bh      = 0.8;      // box height
real gap     = 0.3;      // arrow gap

pen startColor = gray(0.85);
pen procColor  = rgb(0.85, 0.90, 1.00);
pen decColor   = rgb(1.00, 0.95, 0.80);
pen outColor   = rgb(0.90, 1.00, 0.90);

void boxLabel(pair c, string s, pen fillpen) {
    pair bl = c + (-bw/2, -bh/2);
    pair tr = c + (bw/2, bh/2);
    fill(box(bl, tr), fillpen);
    draw(box(bl, tr), black+1pt);
    label(s, c, fontsize(9pt));
}

void arr(pair a, pair b) { draw(a--b, arrow=Arrow(TeXHead)); }
void arrPath(path p) { draw(p, arrow=Arrow(TeXHead)); }

// --- Flowchart boxes (computed from parameters) ---
pair pStart  = (xc,     yTop);
pair pInput  = (xc,     yTop - dy);
pair pDecide = (xc,     yTop - 2*dy);
pair pOutYes = (xLeft,  yTop - 2.5*dy);
pair pOutNo  = (xRight, yTop - 2.5*dy);
pair pEnd    = (xc,     yTop - 4*dy);

boxLabel(pStart,  "Start",       startColor);
boxLabel(pInput,  "Input $x$",   procColor);
boxLabel(pDecide, "$x > 0$?",    decColor);
boxLabel(pOutYes, "Output",      outColor);
boxLabel(pOutNo,  "Output",      rgb(1.00, 0.85, 0.85));
boxLabel(pEnd,    "End",         startColor);

// --- External annotations ---
label("{\small positive number}",    (xLeft,  pOutYes.y - 0.9), fontsize(8pt));
label("{\small non-positive number}", (xRight, pOutNo.y  - 0.9), fontsize(8pt));

// --- Arrows (computed from box edges) ---
arrPath((xc, pStart.y  - bh/2 - gap)--(xc, pInput.y  + bh/2 + gap));
arrPath((xc, pInput.y  - bh/2 - gap)--(xc, pDecide.y + bh/2 + gap));
arrPath((xc - bw/2 - gap, pDecide.y)--(pOutYes.x + bw/2 + gap, pOutYes.y));
arrPath((xc + bw/2 + gap, pDecide.y)--(pOutNo.x  - bw/2 - gap, pOutNo.y));
arrPath((pOutYes.x, pOutYes.y - bh/2 - gap)--(xc - bw/4, pEnd.y + bh/2 + gap));
arrPath((pOutNo.x,  pOutNo.y  - bh/2 - gap)--(xc + bw/4, pEnd.y + bh/2 + gap));
```

### Example 3: Function plot
**User**: Plot y = sin(x) and y = cos(x) on [0, 2pi]

```asy
import graph;
size(10cm, 6cm, IgnoreAspect);

real f(real x) { return sin(x); }
real g(real x) { return cos(x); }

draw(graph(f, 0, 2pi), red, "$\\sin x$");
draw(graph(g, 0, 2pi), blue, "$\\cos x$");

xaxis("$x$", 0, 2pi, arrow=Arrow,
      Ticks(Label(), Step=pi/2, step=pi/4));
yaxis("$y$", -1.2, 1.2, arrow=Arrow);

legend();
```
