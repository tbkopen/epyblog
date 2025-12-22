---
layout: post
# author: "Epy Blog"
title: "From Lagaris to Raissi: The Evolution of PINN Formulations"
tags:
  - PINNs
  - Deep Learning
usemathjax:     true
more_updates_card: false
giscus_term: pinn-evolution-intro
yt_community_link: false
excerpt_separator: <!--more-->
---

When people talk about Physics-Informed Neural Networks today, they usually mean one thing:  
a neural network trained with a PDE residual loss and a few penalty terms for boundary and initial conditions.<!--more-->

That picture has become so familiar that it feels almost inevitable. Write down the governing equations, add losses for constraints, tune a few weights, and let optimization take care of the rest. For many, this *is* what PINNs are.

But this was not how PINNs started.

The earliest formulations did not treat boundary conditions as soft objectives competing for attention during training. They didn’t even allow the network to see them as something it could violate. Boundary conditions were **eliminated analytically**, before learning began.

The neural network never had a chance to get them wrong.

That older idea is mostly forgotten today. And that matters — because many of the stability issues we now accept as “normal PINN behavior” were simply not present in those early formulations.

To understand why modern PINNs behave the way they do, it helps to step back and see how we arrived here.



## The Lagaris Era: When Boundary Conditions Were Not Optional

The first widely cited neural-network-based solvers for differential equations came from Lagaris, Likas, and Fotiadis in the late 1990s ([link](https://arxiv.org/abs/physics/9705023)). These works predate the term “PINN,” but the conceptual foundations were already in place: use a neural network to approximate an unknown function and enforce the governing equation through differentiation.

What sets these methods apart is not the use of neural networks, but *how* they are used.

The crucial design choice was this:

> **The neural network does not represent the solution directly.**

Instead, the solution is written as a *trial function*:

$$
f(x) = g(x) + h(x)\,N(x)
$$

Here:

- $g(x)$ is a known function that satisfies the boundary conditions exactly  
- $h(x)$ vanishes on the boundary  
- $N(x)$ is the neural network output  

Because $h(x) = 0$ on the boundary, the network’s contribution literally disappears there. No matter how poorly trained the network is, the boundary condition is always satisfied by construction.

This is what we now call **hard boundary enforcement**.

There is something deeply numerical about this idea. It echoes a mindset that predates neural networks entirely — one where constraints are not “encouraged,” but **designed into the solution space itself**:

- Modify the solution space  
- Eliminate degrees of freedom  
- Encode constraints analytically rather than penalizing them  

From a solver perspective, this is elegant in a very classical sense. The optimization never wanders into invalid territory, because that territory has been removed.



## Why Lagaris PINNs Were So Stable (and Why That Matters)

If you have ever implemented a Lagaris-style PINN, one thing stands out almost immediately:

They converge surprisingly well.

Even with:

- Small networks  
- Plain SGD  
- No normalization tricks  
- No loss balancing  
- No fancy schedulers  

This behavior often feels disproportionate to how little machinery is involved.

The reason, however, is straightforward.

The optimization problem is **well-conditioned** because the network has a narrow and well-defined responsibility. It is not being asked to juggle competing objectives or decide how much attention each constraint deserves.

The network is not trying to:

- Learn the solution  
- Learn the boundary condition  
- Decide how much to care about each  

The boundary has already been handled analytically. The only task left is to reduce the differential equation residual over the domain.

This separation of responsibilities matters more than it first appears. In numerical analysis terms, Lagaris PINNs reduce the effective degrees of freedom *before* optimization begins. The learning problem is simpler not because the network is smaller, but because the space it explores is already structured.



## The Limits of the Lagaris Approach

So why didn’t this formulation become the standard?

Because it doesn’t scale gracefully.

The strength of the Lagaris approach — explicit control over the solution space — relies on the ability to construct suitable trial functions. That works beautifully when the problem is simple and the geometry is cooperative. But many problems are neither.

As soon as you move beyond simple 1D ODEs, things get messy:

- Complex geometries  
- Irregular domains  
- Mixed boundary conditions  
- Time-dependent problems  
- High-dimensional PDEs  

Constructing trial functions in these settings is no longer a minor preprocessing step. It becomes a substantial modeling effort in its own right.

For simple domains, one can write:

$$
f(x,y) = g(x,y) + x(1-x)y(1-y)\,N(x,y)
$$

But for real engineering geometries — domains imported from CAD, evolving interfaces, heterogeneous materials — this approach quickly runs out of road.

The method remains mathematically clean, but **geometrically brittle**. Its success depends on how much structure the problem is willing to reveal upfront.

And that brittleness is what opened the door to a different philosophy.



## The Raissi Shift: Making PINNs General-Purpose

When Raissi, Perdikaris, and Karniadakis introduced what we now recognize as modern PINNs ([link](https://www.sciencedirect.com/science/article/abs/pii/S0021999118307125)), their goal was not to refine the Lagaris idea. It was to remove its biggest barrier.

Their key move was simple:

> Let the neural network represent the solution directly.

$$
f(x,t) \approx N(x,t)
$$

Then enforce *everything* via losses:

- PDE residual loss  
- Boundary condition loss  
- Initial condition loss  
- Data mismatch loss (if available)  

This is what we now call **soft enforcement**.

Nothing is guaranteed. Everything is encouraged.

From a usability standpoint, this was a decisive shift. PINNs no longer required handcrafted trial functions. The same formulation could be applied across domains, dimensions, and problem types with minimal modification.

This is what made PINNs feel like a universal solver template.

And that’s why this formulation won.



## What Soft Enforcement Quietly Changed

The price of this flexibility is often underestimated.

In the Raissi formulation, the optimizer is no longer solving a single, well-posed objective. It is balancing **multiple competing objectives** simultaneously:

- Reduce PDE residual  
- Satisfy boundary conditions  
- Match initial conditions  
- Possibly fit data  

These objectives live on different scales, act on different regions of the domain, and often produce gradients that are neither aligned nor comparable.

There is no reason their gradients should be balanced by default.

So practitioners started adding:

- Loss weights  
- Adaptive weighting schemes  
- Curriculum strategies  
- Residual-based sampling  
- Domain decomposition  
- Multi-network architectures  

None of this complexity existed in the Lagaris formulation.

Not because Lagaris PINNs were simplistic, but because the most troublesome constraints had already been resolved *before* optimization instead of being negotiated *during* optimization.



## The Hidden Cost: Ill-Conditioned Optimization

One symptom shows up again and again in modern PINNs:

You get smooth-looking solutions with low residuals — and wrong physics.

This happens because:

- The network can trade PDE accuracy for boundary satisfaction  
- Or satisfy boundaries locally while violating physics elsewhere  
- Or fit data while drifting from the governing equation  

In inverse problems, this becomes particularly dangerous. Parameters may converge cleanly and repeatably — to values that are simply incorrect.

Lagaris-style PINNs don’t eliminate all failure modes, but they remove this particular one. The boundary is not something the optimizer can bargain with.



## Hard vs Soft BCs Is Not a Style Choice

Today, “hard vs soft boundary conditions” is often presented as a stylistic or implementation detail.

It isn’t.

It is a statement about **where constraints live**:

- Hard BCs live in the function space  
- Soft BCs live in the loss landscape  

That difference changes:

- **Identifiability** - _This is about whether the problem has a unique answer_. When constraints live in the function space, the network is restricted to physically valid solutions, reducing ambiguity. When constraints live in the loss, different solutions or parameter values can satisfy the loss approximately, especially in inverse problems. 
- **Conditioning** - _This is about how easy the problem is to optimiz_e. Hard constraints remove restricted directions before training begins, leading to more stable gradients. Soft constraints introduce competing objectives into the loss, often making convergence sensitive to scaling and weights. 
- **Optimization trajectories** - _This refers to how training evolves over time_. With hard constraints, training is guided mainly by the physics residual and tends to progress smoothly. With soft constraints, optimization often shifts between loss terms, leading to plateaus or oscillations unrelated to the physics. 
- **Failure modes** - _This is about how things go wrong_. Hard enforcement usually fails in visible, structural ways. Soft enforcement can fail quietly, producing smooth, low-loss solutions that still violate physics or converge to incorrect parameters.  

Neither approach is universally better. But treating them as equivalent obscures why PINNs succeed in some settings and struggle in others.



## Why the Field Didn’t Circle Back (Yet)

A natural question follows:  
If hard enforcement is so powerful, why don’t we combine it with modern PINNs?

Some people do — cautiously.

The obstacle is not theoretical. It is practical:

- Automatic construction of trial functions is hard  
- Geometry-aware basis design is nontrivial  
- PDE libraries prioritize flexibility over structure  

Interestingly, many modern developments — operator learning, constrained architectures, physics-aware bases — quietly move back toward the Lagaris philosophy, even when they don’t say so explicitly.



## A More Honest Way to Think About PINN Evolution

Lagaris PINNs were **numerical-method-first**.  
Raissi PINNs were **machine-learning-first**.

One reduced the problem before optimization.  
The other delegated everything to optimization.

Much of modern PINN research can be understood as an attempt to recover conditioning that was once obtained analytically.

When you see papers proposing:

- Adaptive weights  
- Constraint-aware networks  
- Domain-wise decomposition  
- Physics-preserving architectures  

You’re watching the field rediscover ideas that classical numerical analysts never abandoned.

## References
* Lagaris, I. E., Likas, A., & Fotiadis, D. I. (1998). Artificial neural networks for solving ordinary and partial differential equations. IEEE transactions on neural networks, 9(5), 987-1000.
* Raissi, M., Perdikaris, P., & Karniadakis, G. E. (2019). Physics-informed neural networks: A deep learning framework for solving forward and inverse problems involving nonlinear partial differential equations. Journal of Computational physics, 378, 686-707.

{% capture mycard %}

For readers who want to know more about PINN fromulations in practice — including parameter learning schedules, loss coupling effects, scaling choices, and how incorrect parameters can still produce low residuals — there is a hands-on walkthrough available as part of the **_PINNs Masterclass_**.

{% endcapture %}

{% include promo-card-md.html
   heading="Further exploration (optional)"
   body=mycard
   button_link="https://exly.co/PvxFUL"
   button_text="Learn More →"
%}