---
layout: post
# author: "Epy Blog"
title: "The Boundary Condition Lie: When “Satisfied” Doesn’t Mean “Enforced” in PINNs"
tags:
  - PINNs
  - Deep Learning
usemathjax:     true
more_updates_card: false
giscus_term: soft-vs-hard-bcs-2
yt_community_link: false
excerpt_separator: <!--more-->
---

Boundary conditions are where physics stops being abstract and becomes accountable. A PDE can be elegant, a loss function can be “decreasing,” a solution can look smooth on a plot — and still be wrong in the one place you actually promised correctness: the boundary. <!--more-->

In physics-informed neural networks (PINNs), *hard* vs *soft* boundary conditions sounds like a minor implementation choice. It isn’t. It decides whether the boundary is a **constraint** or merely a **preference**. And that difference is exactly where many PINNs fail quietly: not with exploding gradients or obvious divergence, but with solutions that look plausible, converge nicely, and then refuse to match what the boundary condition actually means.



## Boundary conditions: the one part you can’t “kind of” satisfy

A boundary condition is not an extra data point. It is a statement about the admissible solution space.

If you’re solving a PDE in a domain $\Omega$ with boundary $\partial\Omega$, the boundary condition says: among all functions that might reduce the PDE residual inside $\Omega$, only those that obey a specific behavior on $\partial\Omega$ are allowed.

In classical numerical methods, this is enforced structurally:

* In finite elements, Dirichlet conditions often constrain degrees of freedom directly (or through penalty / Nitsche variants with known tradeoffs).
* In finite differences, boundary values can be inserted into the stencil or fixed explicitly.

PINNs break that comfort. They don’t discretize a solution in a way that naturally “pins” boundary values. They optimize a neural function $u_\theta(x)$ to reduce a loss. The boundary condition becomes a decision: **Do you restrict the function class so the boundary is always satisfied?** Or **do you merely encourage the optimizer to satisfy it?**

That is the hard vs soft split.



## Soft boundary conditions: the boundary as a negotiable term

A *soft* boundary condition is added as a penalty:

$$
\mathcal{L}(\theta)
= \mathcal{L}_{\text{PDE}}(\theta)

* \lambda_{\text{BC}}\mathcal{L}_{\text{BC}}(\theta)
  $$

For a Dirichlet BC $(u(x)=g(x))$ on $(\partial\Omega)$, a typical term is:

$$\mathcal{L}_{\text{BC}} = \frac{1}{N} \sum_{i=1}^{N} (u_\theta(x_i) - g(x_i))^2,\; x_i \in \partial\Omega$$


The optimizer is free to trade BC error against PDE residual. If the PDE term is hard to reduce (stiffness, sharp layers, poor scaling, noisy derivatives), it may “pay” some boundary violation to get a bigger reduction elsewhere — especially early in training when gradients are dominated by whatever term is currently easiest to optimize.

Soft BCs are attractive for good reasons:

* They are easy to implement for any BC type.
* They generalize to irregular domains and mixed conditions.
* They work naturally with noisy boundary measurements (in inverse problems, “BC” might be data).

But they are *not enforcement*. They are persuasion.

When you use soft BCs, you are implicitly trusting the optimizer to behave like a constrained solver. It often doesn’t.



## Hard boundary conditions: the boundary as a structural guarantee

A *hard* boundary condition is built into the parameterization so it holds **for all** ($\theta$), not just at convergence.

For Dirichlet BCs, a common idea is to write the network output as:

$$
u_\theta(x) = g(x) + \phi(x),N_\theta(x)
$$

where:

* $g(x)$ matches the boundary condition on $\partial\Omega$
* $\phi(x)=0$ on $\partial\Omega$ but nonzero inside $\Omega$
* $N_\theta(x)$ is a free neural network

Then on the boundary, $u_\theta(x)=g(x)$ exactly, regardless of training.

Hard BCs feel like the “right” way: why not guarantee the thing you know?

Because “guarantee” is not free.

Hard enforcement changes the geometry of the optimization landscape. It can create steep gradients near the boundary, amplify conditioning issues, and force the network to represent difficult interior behavior through $\phi(x)N_\theta(x)$, which may be a harder function class than $N_\theta(x)$ alone. It’s not uncommon to see training become stable but slow, or stable but biased, if the enforced form fights the true solution structure.

Hard BCs shift the burden from optimization to representation.

Soft BCs shift the burden from representation to optimization.

The mistake is thinking one is “more correct” in all cases. The deeper truth is that both can fail — but in different, recognizable ways.



## The first lie: “My boundary loss is small, so the boundary is satisfied”

This is the most common comfort blanket in PINN practice. The loss is a single scalar. If $\mathcal{L}_{\text{BC}}$ is small, people mentally translate that to “BC satisfied.”

But “small” is relative to scaling, sampling, and the rest of the loss. Three mechanisms make this interpretation unreliable.

### 1) Small loss does not mean small maximum error

Most BC losses are *mean* errors over sampled boundary points. A function can have low mean-squared error and still violate the boundary badly in a localized region — corners, interfaces, or near singularities.

If you’ve ever plotted the boundary error and seen it “mostly fine” except a stubborn bulge near one corner, you’ve already met this. The scalar loss stayed calm while the boundary condition was visibly not.

### 2) The optimizer learns what is cheap, not what is important

When gradients are imbalanced, the optimizer follows the steepest useful descent direction. If boundary gradients are small compared to PDE residual gradients (or vice versa), training becomes a negotiation that has nothing to do with correctness and everything to do with conditioning.

PINNs are especially vulnerable because the PDE loss involves derivatives, and derivative magnitudes can differ by orders of magnitude depending on nondimensionalization, domain scaling, activation saturation, and the PDE itself.

### 3) A low boundary loss can be a *symptom* of an overly smooth, wrong solution

This one is subtle and common in diffusion-dominated problems and low-frequency regimes. A network can satisfy boundary values reasonably well by producing a smooth function that interpolates boundaries, while still missing interior physics (or missing sharp layers). The BC term looks great. The PDE residual might look “okay” on average. The solution is wrong where it matters.

Hard BCs don’t automatically fix this. They just remove the boundary from the negotiation, which can make the *interior compromise* easier to hide.



## The deeper mechanism: soft BCs create a hidden constrained-optimization problem you’re not actually solving

Soft BC training is, in effect, a penalty method. Classical constrained optimization tells you what happens with penalty methods:

* If the penalty weight is too small, constraints are violated.
* If the penalty weight is too large, the optimization becomes ill-conditioned and hard to solve.

This is not a PINN-specific insight; it’s just what penalty methods do.

PINNs add an extra complication: the “constraint violation” is not a simple linear constraint. It’s a function constraint learned through a nonlinear network, coupled to a PDE residual that depends on derivatives of the same network.

So the BC penalty is not merely competing with the PDE penalty — it is competing through shared parameters and shared representational limits.

That’s why tuning $\lambda_{\text{BC}}$ can feel irrational. You adjust it by 10× and training either:

* refuses to reduce PDE residual meaningfully, or
* produces a visually plausible solution that slightly violates the boundary forever, or
* suddenly snaps into a different regime after many epochs.

This isn’t mysticism. It’s the penalty method interacting with a nonconvex function approximator.

Hard BCs are appealing because they remove the penalty method failure mode. But then the failure mode shifts: the network must express the correct interior physics under a forced form. And if $\phi(x)$ is poorly chosen (especially near corners, complex geometries, or mixed BCs), you can create representational bottlenecks that no optimizer can fix.



## You’ve probably seen this: “The PDE residual decreases nicely, but the boundary looks off”

A recognizable pattern:

* Training curves look healthy.
* PDE residual goes down smoothly.
* Boundary loss goes down somewhat, then plateaus.
* When you plot $u$ along the boundary, it’s consistently biased or slightly shifted.
* Increasing $\lambda_{\text{BC}}$ makes the PDE residual worse or makes training unstable.

This is not random bad luck. It often means the optimizer has found a compromise solution in a valley where improving BC fit would require climbing out of a region that currently gives cheap PDE reduction. In other words: the network discovered an “acceptable” function for the loss weights you gave it — not the function you intended.

A second variation is even more dangerous:

* Boundary loss becomes very small.
* The boundary plot looks perfect.
* The interior is wrong, but you don’t notice until you compare against a reference or compute a quantity of interest.

This happens when the boundary is easy to satisfy (especially Dirichlet) and the PDE residual can be reduced by a smooth, low-frequency function that doesn’t capture the correct solution class. The BC term gives you false confidence because it is the easiest part of the problem.



## What hard boundary conditions quietly change

When you enforce Dirichlet BCs hard, you eliminate one degree of freedom: the network cannot “use” boundary violation to reduce interior residual. That sounds strictly better — but it changes learning dynamics in ways that matter.

### 1) Gradients can concentrate away from the boundary

With a hard form $u=g+\phi N$, the boundary is satisfied by construction, but the PDE residual still depends on derivatives of $\phi N$. If $\phi$ is small near the boundary, the network’s ability to adjust behavior near the boundary can become constrained. This can slow down learning of boundary layers or steep gradients that live near $\partial\Omega$.

### 2) The parameterization can bias the solution class

Hard enforcement forces the solution to live in a subspace. If the true solution has behavior that is awkward to express as $g+\phi N$ — especially with mixed BCs, discontinuities, or non-smooth boundaries — the network can satisfy the boundary perfectly and still be systematically wrong inside.

### 3) “Hard BC” doesn’t mean “hard physics”

Many people unconsciously upgrade their trust: if BC is hard, they assume the PINN is now more physically faithful. But interior residual minimization is still a soft penalty. If anything, hard BC can mask interior failure because one visibly checkable constraint is now guaranteed, making the outputs look more legitimate.

Hard BCs don’t remove the need for skepticism. They just relocate it.



## Mixed and Neumann boundary conditions: where the story gets nastier

Dirichlet BCs are the cleanest case for hard enforcement. Once you move to Neumann or Robin conditions, “hard” becomes harder — and sometimes not worth the contortions.

For a Neumann BC $\frac{\partial u}{\partial n}=h(x)$ on $\partial\Omega$, enforcing this structurally is not as straightforward as forcing values. You’re enforcing a derivative constraint. You can build parameterizations that satisfy certain derivative constraints, but they are geometry-dependent and often brittle.

So practitioners default to soft enforcement for Neumann/mixed BCs. That’s reasonable — but it comes with a specific risk:

Neumann terms involve derivatives, which tend to be noisy and scale-sensitive in PINNs. If your PDE residual already contains second derivatives (e.g., diffusion), you are now balancing derivative-based penalties against derivative-based penalties. Small nondimensionalization mistakes can completely reorder the gradient magnitudes.

If you’ve ever seen a PINN that fits Dirichlet boundaries beautifully but produces a wrong flux, this is usually why: the flux constraint was treated as “just another term,” but it lived on a different numerical scale, and the optimizer quietly deprioritized it.



## The real cost of getting this wrong: not failure, but false completion

The worst outcome isn’t divergence. It’s *closure* — the feeling that the problem is solved because the curves look good.

When boundary conditions are handled incorrectly, you can spend days doing “reasonable” things:

* adding more collocation points,
* training longer,
* switching Adam to L-BFGS,
* changing activation functions,
* tweaking learning rates,

and still sit inside the same conceptual mistake: treating boundary satisfaction as a matter of taste rather than a statement about the admissible function space.

This is why BC choice produces a specific kind of wasted time. You can’t brute-force your way out of a constraint mismatch. If you are solving the wrong optimization problem — even slightly — more compute just makes you more confident in the wrong answer.



## A couple of quiet diagnostics experienced practitioners reach for

People who’ve been burned by this tend to stop trusting aggregate losses early. They do small, almost boring checks that reveal whether the boundary is genuinely under control.

One is to look at the **boundary error as a function**, not a scalar: not “BC loss,” but “where on the boundary do I violate, and how does that pattern evolve?” Corners and interfaces tell you more than averages.

Another is to compare **relative gradient influence** between PDE and BC terms — not as a philosophical exercise, but because it predicts what the optimizer is actually optimizing. If one term’s gradients are consistently tiny, no amount of hope will make that term matter.

These aren’t full workflows. They’re reminders of what the loss curve refuses to tell you.



## So which should you trust?

If you’re looking for a universal rule, you won’t get one. Hard and soft boundary conditions are not competing “options.” They are two different answers to a deeper question:

**Should the boundary be guaranteed by construction, or negotiated by optimization?**

Hard BCs reduce one class of silent failure and increase another. Soft BCs are flexible and general, but they rely on penalty behavior and scaling sanity that many problems don’t naturally provide.

A pragmatic engineer eventually treats boundary handling as part of the modeling, not a checkbox. The right choice depends on the PDE type, boundary type, geometry, expected regularity, and what “wrong” looks like for the quantity you care about.

And that brings us to the uncomfortable open tension:

If a PINN solution satisfies the boundary *exactly* (hard BC) but only satisfies the PDE *in distribution* (soft residual), what does “physical correctness” even mean — and where should you demand exactness next?


{% capture mycard %}

For readers who want to see how boundary conditions are handled in real PINN implementations — including output transforms, loss balancing, and diagnostics — there is a hands-on walkthrough available as part of the **_PINNs Masterclass_**.

{% endcapture %}

{% include promo-card-md.html
   heading="Further exploration (optional)"
   body=mycard
   button_link="https://exly.co/PvxFUL"
   button_text="Learn More →"
%}