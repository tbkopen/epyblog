---
layout: post
# author: "Epy Blog"
title: "PINNs Beyond PDEs: What Changes When the Physics Is Written as an Integral"
tags:
  - PINNs
  - Deep Learning
usemathjax:     true
more_updates_card: false
giscus_term: pinns-for-integral-eqns
yt_community_link: false
excerpt_separator: <!--more-->
---

Most people first encounter PINNs through partial differential equations, and for good reason. PDEs are how physics is usually introduced, analyzed, and benchmarked. <!--more-->They also align nicely with the intuition behind PINNs: derivatives encode local behavior, and the network is trained to make those local behaviors consistent everywhere in the domain.

In a PDE formulation, the idea of “physics violation” is easy to picture. If the solution bends the wrong way at a point, the residual at that point becomes large. The network feels the error immediately.

At some point, though, the formulation changes.

You may rewrite the same physics using an integral representation. Perhaps you are using a boundary integral method to eliminate the domain. Perhaps a Green’s function formulation makes the problem cleaner. Perhaps the system has memory, long-range interactions, or convolution kernels that make a differential form awkward or unnatural.

What is important here is that *the physics itself has not changed*. Only the mathematical form has.

And that change — from local to global — turns out to matter far more for PINNs than it first appears.



## Why Integral Equations Feel Comforting at First

From a practical PINN perspective, integral equations feel almost friendly.

There are no high-order derivatives to compute. No fragile second or third derivatives that amplify noise. No boundary conditions enforced through subtle derivative constraints. Automatic differentiation, which is often the most painful part of PDE-based PINNs, suddenly plays a much smaller role.

A typical integral equation might be written as

$$
u(x) = f(x) + \int_\Omega K(x,s)\,u(s)\,ds,
$$

or, equivalently, in residual form,

$$
\mathcal{R}(x) = u(x) - f(x) - \int_\Omega K(x,s)\,u(s)\,ds = 0.
$$

Here, $x$ denotes the spatial location at which the field and residual are evaluated, while $s$ is the integration variable spanning the domain $\Omega$. For each fixed $x$, the integral operator aggregates contributions from all $s$, weighted by the kernel $K(x,s)$.

From an implementation standpoint, this looks almost too clean. You sample points in the domain, approximate the integral numerically, define a residual, and minimize a loss. There is no need to worry about differentiability of the network output beyond continuity.

It is very natural at this stage to expect training to be easier and more reliable than in the PDE case.

What actually happens is subtler: training becomes *quieter*, not necessarily better.



## The Shift from Local to Global Physics

The key conceptual shift is that **integral equations enforce physics globally, not locally**.

In a PDE-based PINN, a local error produces a local penalty. If the solution violates the governing equation at a point, the residual at that point reacts strongly. Errors are spatially sharp and difficult to hide.

An integral residual behaves very differently. It aggregates information over a region of the domain. Local errors are averaged together with correct regions.

As a result, a solution can be noticeably wrong in certain parts of the domain and still satisfy the integral constraint with surprising accuracy.

This is not a numerical artifact, and it is not something that can be “fixed” by tuning hyperparameters. It is a direct consequence of how integral operators work.



## Why Smoothing Matters More Than It Sounds

To understand why this matters so much, consider the integral operator

$$
\int_\Omega K(x,s)\,u(s)\,ds.
$$

Unless the kernel $K$ is extremely localized, a perturbation in $u(s)$ at a specific location has only a weak effect on the integral. Information is spread out. Sharp features are blurred.

In operator-theoretic language, many integral operators encountered in physics are **compact**. Compact operators damp high-frequency components of a function. They compress information.

From a learning perspective, this has a critical implication: the mapping from $u$ to the residual is many-to-one in practice. Many distinct functions produce nearly identical residuals.

This is where the loss landscape changes character. Valleys become wide. Curvature becomes weak. The optimizer has little incentive to favor one candidate solution over another.

Training looks calm. Loss decreases smoothly. Gradients remain well behaved.

And yet, the network may be converging to a solution that is globally acceptable and locally wrong.



## What the Loss Is Actually Measuring

A typical PINN loss for an integral equation looks like

$$
\mathcal{L}
=
\frac{1}{N_r}\sum_{i=1}^{N_r}
\left|
u_\theta(x_i)
-
f(x_i)
-
\int_\Omega K(x_i,s)\,u_\theta(s)\,ds
\right|^2
+
\mathcal{L}_{\text{data}}.
$$

What is important here is not just what is included, but what is missing.

There is no term that enforces pointwise consistency in the way a differential residual does. All physics information passes through the integral operator before it reaches the loss.

In effect, the loss measures **agreement after smoothing**, not local correctness.

If you only watch the loss curve, it is very easy to believe the network has learned the physics faithfully.



## When Quadrature Quietly Becomes Part of the Model

In practice, the integral is never computed exactly. It is approximated using quadrature:

$$
\int_\Omega K(x,s)\,u(s)\,ds
\;\approx\;
\sum_{j=1}^{N_q} w_j\,K(x,s_j)\,u_\theta(s_j).
$$

At this point, three different approximations are tightly coupled:  
the neural approximation of $u$, the quadrature approximation of the integral, and the physics constraint itself.

This coupling is easy to underestimate.

A coarse quadrature can artificially reduce the residual. Certain oscillations or localized errors may never be “seen” by the quadrature points. The network may learn to exploit this invisibility, not intentionally, but because the loss provides no reason to do otherwise.

In integral-equation PINNs, numerical integration is not just a numerical detail. It becomes part of the learned model.

This is one of the most dangerous aspects of the approach: failure often looks like success.



## Identifiability Becomes a Serious Issue

Integral equations are frequently used in inverse problems — identifying source terms, kernel parameters, or material response functions.

Unfortunately, integral operators tend to **reduce identifiability**, not improve it.

Small changes in parameters often produce very small changes in the integral. Sensitivities such as

$$
\frac{\partial}{\partial \theta}
\left(
\int_\Omega K(x,s)\,u_\theta(s)\,ds
\right)
$$

can be weak, especially when the kernel is smooth or the domain is large.

From the optimizer’s point of view, this produces long, flat directions in the loss landscape. Parameters can drift without triggering a strong response in the loss. Training converges. Nothing explodes. Nothing looks obviously wrong.

That quietness is precisely the risk.



## How the Training Loop Reflects All of This

At a high level, the training loop for an integral-equation PINN looks like this:

```text
initialize network weights θ

for each training step:
    sample collocation points x_i
    sample quadrature points s_j

    predict u(x_i; θ)
    predict u(s_j; θ)

    approximate integral using quadrature
    compute integral residual

    compute data mismatch (if available)
    total loss = integral physics loss + data loss

    backpropagate
    update θ
````

The structure of the loop itself tells the story. Training is dominated by sampling, averaging, and integration. Local differential structure plays almost no role.

Once you see this, the changed behavior of PINNs stops being mysterious.



## Why Training Often Feels “Too Easy”

A common experience with integral-equation PINNs is that training feels unusually smooth. Loss curves are clean. Gradients are stable. Optimization rarely becomes unstable.

This is not necessarily good news.

It usually means the integral operator is smoothing the error signal so effectively that the optimizer never feels strong corrective forces. The network converges quickly — and remains uncertain about where it is wrong.



## Where Integral PINNs Truly Make Sense

There are cases where this global behavior is exactly what you want.

Boundary integral formulations, long-range interaction models, and problems where conservation laws matter more than pointwise accuracy all benefit from an integral perspective. In such settings, smoothing is not a defect. It is the physics.

The key is recognizing when you are in that regime.



## A Quiet Link to Operator Learning

It is not an accident that operator-learning methods exist.

DeepONets, neural operators, and PINOs emerged from the realization that learning operators — especially integral ones — requires different inductive biases than enforcing local differential constraints.

PINNs can be applied to integral equations, but they often work *against* the nature of the operator rather than with it.

Understanding this boundary helps avoid unrealistic expectations.


{% capture mycard %}

For readers interested in how integral formulations are handled in real PINN implementations — including quadrature design, residual evaluation, boundary handling, and diagnostics for hidden errors — there is a hands-on walkthrough available as part of the **_PINNs Masterclass_**.

{% endcapture %}

{% include promo-card-md.html
   heading="Further exploration (optional)"
   body=mycard
   button_link="https://exly.co/PvxFUL"
   button_text="Learn More →"
%}