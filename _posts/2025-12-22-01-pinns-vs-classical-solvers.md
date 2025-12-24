---
layout: post
# author: "Epy Blog"
title: "PINNs vs Classical Solvers: <br>Why We Use PINNs When FEM or FDM Already Work"
tags:
  - PINNs
  - Deep Learning
usemathjax:     true
more_updates_card: false
giscus_term: pinns-vs-classical-solvers
yt_community_link: false
excerpt_separator: <!--more-->
---

There is a question I keep hearing, again and again, in different forms.

>“Are PINNs better than FEM?”  
“Can PINNs replace finite difference or finite element methods?”  
"We already have FEM or FDM solving this problem—so why do we need PINNs?"  
“Why is my PINN so inaccurate compared to a spectral solver?”<!--more-->

The question sounds reasonable. If two methods solve the same PDE, surely we can line them up, compare errors, runtimes, and memory, and declare a winner.

That instinct is human. It is also where most of the confusion begins.

This post is not about defending PINNs, nor about dismissing classical solvers. It is about why this comparison usually asks the wrong question, and why asking it repeatedly leads people to disappointment, false expectations, and misapplied tools.



### A Familiar Technical Situation

Consider a standard PDE problem—say beam bending, steady-state heat conduction, or diffusion on a bounded domain with well-defined geometry and boundary conditions.

>The governing equation is known. The coefficients are known. Boundary conditions are prescribed cleanly. The geometry is fixed and well-resolved. You mesh the domain, refine until convergence, and the numerical solution behaves exactly as expected. Residuals drop, error norms converge, and the solver is stable.

Now modify the situation slightly.

>You still believe the governing equation is correct, but one coefficient is uncertain or spatially varying in a way you cannot measure directly. Boundary conditions are partially known, but parts of the boundary are inaccessible or noisy. Inside the domain, you have sparse measurements—sensor data collected at a few locations, not a full field.

Before PINNs, problems like this were handled using inverse methods layered on top of classical solvers: parameter estimation loops, adjoint methods, regularization strategies, or repeated forward solves wrapped inside an optimization routine. These approaches work, but they require careful problem-specific construction and often significant effort.

PINNs enter precisely at this boundary between *forward simulation* and *inference*.

And this is where the comparison usually starts to go wrong.



### Why the Comparison Feels Natural (But Isn’t)

Classical solvers—finite element methods, finite differences, spectral methods—are trusted for good reason. They come with mathematical guarantees, convergence theory, and decades of engineering validation.

PINNs arrive with a bold framing: solving PDEs using neural networks trained by minimizing physics-informed loss functions.

Naturally, people ask whether they are faster, more accurate, or more efficient.

Benchmark studies often take a clean PDE with known solutions, compare error norms and wall-clock time, and report that PINNs underperform classical solvers.

This leads to skepticism, or sometimes to the conclusion that PINNs are fundamentally flawed.

But this setup quietly assumes something that is rarely stated explicitly: that both methods are solving the *same optimization problem*.

They are not.



### What Classical Solvers Actually Optimize

When you solve a PDE using FEM, you are working in a carefully constructed discrete function space.

You select basis functions. You assemble weak forms. You impose boundary conditions as constraints. The numerical solution is the result of enforcing the governing equations exactly within that discrete space.

The errors you observe are due to discretization, numerical integration, and finite precision. They are controlled, predictable, and reducible by refinement.

From an optimization perspective, the physics is not something you negotiate with. Once the formulation is fixed, the PDE is enforced by construction.

Classical solvers answer this question:

> Given complete knowledge of the governing equations and boundary conditions, what discrete function satisfies them as accurately as possible?

They are exceptionally good at answering it. That is why they remain the backbone of scientific computing.



### What PINNs Actually Optimize

A PINN approaches the same PDE from a very different angle.

You posit a neural network $u_\theta(x)$ as a function approximator. You evaluate PDE residuals, boundary residuals, and data mismatches at selected points. These quantities are combined into a loss function, which is then minimized using gradient-based optimization.

Nothing is enforced exactly.

Physics becomes a penalty term.  
Boundary conditions become penalty terms.  
Data consistency becomes another penalty term.

Conceptually, the optimization problem looks like:

$$
\mathcal{L}(\theta)
=
\lambda_f \| \mathcal{N}[u_\theta] \|^2
+
\lambda_b \| \mathcal{B}[u_\theta] \|^2
+
\lambda_d \| u_\theta - u_{\text{data}} \|^2
$$

The solution is not the one that *satisfies the PDE*, but the one that best balances competing objectives under the representational limits of the network and the dynamics of optimization.

A PINN answers a different question:

> Among all functions representable by this network, which one best trades off physics consistency, data fit, and regularity under incomplete information?

This difference is subtle but fundamental. Once you see it, many apparent contradictions disappear.



### A Subtle but Critical Issue: Solution Validity

There is another difference between classical solvers and PINNs that rarely shows up in benchmarks, but matters deeply in practice: *what it means for a solution to be physically valid*.

In classical numerical methods, the solution does not merely satisfy a differential equation pointwise. It typically satisfies a broader set of physical constraints embedded in the formulation itself. Energy balance, momentum conservation, flux continuity, symmetry conditions, and compatibility constraints often emerge naturally from the weak form or discrete structure.

Even when these properties are not satisfied exactly, their violation is understood, bounded, and tied to discretization choices. When a classical solver converges, there is an implicit trust that the solution respects the underlying physics in a global sense, not just locally.

PINNs operate differently.

A PINN minimizes a loss function composed of residual terms. If energy conservation, force balance, or other invariants are not explicitly included, the network has no inherent reason to satisfy them. It will simply find a function that reduces the loss most efficiently.

This means it is entirely possible for a PINN to produce a solution with low PDE residuals and smooth visual behavior, yet violate fundamental physical principles. The network has optimized the objective it was given, not the physics one might implicitly assume.

This is where the phrase *physics-informed* acquires real meaning.

A PINN is not physics-informed because it contains a PDE in the loss. It becomes physics-informed only when the solution is examined against the core physical laws that matter for the problem—conservation, balance, invariance, and consistency—and found to respect them.

In practice, this often requires additional diagnostics, auxiliary constraints, or reformulations. Verifying physical validity is not optional in PINNs; it is part of the modeling effort. Without it, a low loss value can give a false sense of correctness.

This difference in how solution validity is established is subtle, but it strongly influences when PINNs can be trusted—and when they should be treated with caution.



### Why Benchmarks Often Feel Unfair

When PINNs are benchmarked against FEM on fully specified forward problems, they are being evaluated in a setting where their core design advantages are irrelevant.

The PDE is known.  
The coefficients are known.  
The boundary conditions are known.  
The domain is fully observable.

In such cases, classical solvers are not just better—they are aligned perfectly with the problem structure.

Expecting PINNs to outperform them here is equivalent to expecting an inference-based method to outperform a direct solver when no inference is required.

When PINNs struggle in these benchmarks, it is not necessarily a sign of failure. It is a sign of misalignment between method and problem.



### Where PINNs Quietly Make Sense

Now return to the modified problem.

You do not know one of the coefficients.  
Boundary conditions are incomplete or noisy.  
Interior data is sparse and irregular.  
The problem mixes physics constraints and observations.

This is where classical solvers begin to require significant augmentation: inverse formulations, regularization choices, and repeated forward solves. These approaches can work very well, but they demand careful, often problem-specific engineering.

PINNs naturally operate in this space.

You can treat unknown coefficients as trainable variables.  
You can combine interior data and physics in a single objective.  
You can tolerate missing or uncertain boundary information.

From a benchmarking perspective, this looks messy. From a modeling perspective, it is often exactly what is needed.

This is why PINNs sometimes appear unimpressive in clean numerical studies yet find traction in applied, data-constrained settings.



### Where PINNs Should Not Be Used

It is equally important to be clear about where PINNs are a poor choice.

If the problem is well-posed, fully specified, and requires reliable accuracy guarantees, classical solvers remain the appropriate tool. In such cases, PINNs are typically slower, less accurate, harder to diagnose, and more sensitive to training choices.

PINNs are not a modern replacement for FEM. They do not inherit its guarantees, and treating them as interchangeable often leads to frustration.

Understanding this boundary is not a criticism of PINNs; it is a matter of using tools according to their design.



### The Real Cost of the Wrong Framing

When people ask whether PINNs are “better” than FEM, what they often want is a clear ranking—a sense of which tool to trust.

But framing the discussion this way obscures the more important issue: the structure of the problem itself.

Many reported PINN failures are not methodological failures. They are cases where a method designed for inference is judged as if it were a direct solver.

Conversely, many situations where PINNs are useful do not appear in standard benchmarks at all.



### A More Useful Way to Think About the Choice

Instead of asking whether PINNs outperform classical solvers, it is more informative to examine the assumptions your problem satisfies—or violates.

Is the physics fully known?  
Are boundary conditions complete and reliable?  
Is the domain fully observable?  
Are parameters known a priori?

When these assumptions hold, classical solvers align naturally with the problem.

When they do not, methods that blend physics with data—PINNs included—become relevant, not as replacements, but as tools designed for a different class of questions.



### So finally ...

> PINNs and classical solvers are not trying to answer the same question.  
> They often use the same equations, but they are built for different purposes.  
> Confusion starts when we treat them as direct competitors.  
> Once that difference is clear, many debates fade away, and solver choices become easier to reason about.  
> The comparison does not vanish—it just moves to the right level.  


{% capture mycard %}

For readers who want to know more about PINN fromulations in practice — including parameter learning schedules, loss coupling effects, scaling choices, and how incorrect parameters can still produce low residuals — there is a hands-on walkthrough available as part of the **_PINNs Masterclass_**.

{% endcapture %}

{% include promo-card-md.html
   heading="Further exploration (optional)"
   body=mycard
   button_link="https://exly.co/PvxFUL"
   button_text="Learn More →"
%}