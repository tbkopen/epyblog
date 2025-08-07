---
layout: post
# author: "Epy Blog"
title: "Why Classic RAG Fails for Scientific Papers — And What To Do Instead"
tags:
  - LLMs
  - Retrieval Augmented Generation (RAG)
usemathjax:     true
more_updates_card: false
giscus_term: classic-rag-vs-agentic-rag
yt_community_link: false
excerpt_separator: <!--more-->
---

Retrieval-Augmented Generation (RAG) has become the go-to architecture for building intelligent assistants using large language models. It works incredibly well in use cases like customer support<!--more-->, documentation Q\&A, and product search. But the moment you try applying it to **scientific research papers**, the cracks begin to show. 

As someone working deeply with Physics Informed Neural Networks (PINNs), PDE solvers like DeepXDE, and complex mathematical models, I found that **classic RAG simply can’t handle the reasoning load that scientific documents demand**.

This post walks you through:

* Why standard RAG systems fail in scientific domains
* What specific issues crop up when working with technical PDFs
* And how **Agentic RAG** — a multi-agent, tool-augmented, reasoning-first architecture — solves these problems

Let’s begin with a quick refresher.

## What Classic RAG Gets Right (and Wrong)

**Classic RAG** combines document retrieval with LLM-based generation. It typically works like this:

1. Chunk documents into small blocks (say 500 tokens each)
2. Embed each chunk into a vector space using a model like `text-embedding-ada-002`
3. Store these vectors in a vector database (like FAISS or Weaviate)
4. At query time:

   * Embed the user’s question
   * Find the top-k most similar chunks
   * Feed those chunks to an LLM and generate an answer

This setup is lightweight, scalable, and performant — and it works well when:

* Documents are plain-text and self-contained
* Questions map to localized answers
* No deep reasoning or long-term dependencies are involved

But when you're dealing with scientific papers — like the seminal PINNs paper by Raissi et al., or even implementation docs from DeepXDE — classic RAG begins to collapse under the complexity.

Let’s see why.

{% capture mycard %}

Our **PINNs Masterclass** helps you bridge the gap between theory and code — with crystal-clear walkthroughs, real examples, and zero guesswork.

{% endcapture %}

{% include promo-card-md.html
   heading="Been watching tutorials but want to do more?"
   body=mycard
   button_link="https://exly.co/PvxFUL"
   button_text="Enroll Now →"
%}

## 4 Reasons Classic RAG Fails on Scientific Papers

### 1. **Equations Are Ignored or Misinterpreted**

Scientific knowledge often lives in equations. For example, a governing PDE like:

$$
u_t + \mathcal{N}[u] = 0
$$

encodes a *world of meaning*. It defines the physics being modeled, the assumptions built into the system, and often even the architecture of the neural network used to solve it.

Yet, most embedding models treat such equations as **noise** — a jumble of LaTeX or symbols. They don’t understand the structure, purpose, or dependencies between terms. So even if a key equation is retrieved, it adds no interpretive value when passed to the LLM.

> You might retrieve the chunk, but you can’t reason over it.


### 2. **Semantic Structure Is Lost in Chunking**

Scientific papers aren’t written like blog posts. They have strict structure:

* Introduction
* Background
* Methodology
* Assumptions
* Results
* Discussion

This structure is essential. You can’t answer a question about assumptions by looking at the abstract, or explain results without the setup.

Classic RAG, however, slices papers into flat, equally-sized chunks — with no awareness of what section they belong to. A chunk might begin in the middle of the loss function and end inside a training result.

> Without structural awareness, the LLM gets disconnected fragments, leading to vague or misleading answers.

### 3. **Cross-Section Reasoning Fails**

Scientific reasoning is **distributed**. For example:

* Assumptions appear in one section
* Equations in another
* Results in a third

Answering the question:

> “Why did the authors prefer L-BFGS over Adam?”

might require connecting:

* A discussion on training stability (in results)
* A description of the optimizer (in methods)
* A hint about stiffness or convergence (in equations)

Classic RAG retrieves isolated chunks. It doesn't **follow chains of reasoning**. So answers are often shallow, incomplete, or just wrong.

### 4. **No Comparative Thinking**

Now imagine this question:

> “How does this approach compare to DeepONet?”

Even if you’ve indexed both papers, classic RAG has no mechanism to:

* Align methods side-by-side
* Compare architectures, assumptions, or performance
* Present pros/cons with clarity

There is no memory, no iterative exploration, and no multi-perspective reasoning.

> Classic RAG retrieves facts. It doesn’t build arguments.

## What Is Agentic RAG?

Agentic RAG is a reimagined architecture that brings together:

* **Structured chunking** (not just token-sized blobs)
* **Specialized agents** with specific reasoning roles
* **Tool use** (like SymPy, LaTeX parsers, or code execution)
* **Iterative planning**, rather than one-shot generation

It mimics how a human would approach a research paper:

1. Skim the structure
2. Locate relevant sections
3. Interpret symbols
4. Compare with known methods
5. Synthesize an answer over time

Let’s now walk through **how Agentic RAG solves each of the 4 failures** we discussed earlier.

## How Agentic RAG Fixes the Problems — One by One

### 1. Equation Blindness → **Math-Aware Agents**

Agentic RAG includes a **MathAgent** that:

* Extracts equations using LaTeX or PDF parsers
* Parses them via `latex2sympy` or symbolic interpreters
* Converts them into readable explanations (e.g., "This PDE models conservation of mass")

It also stores metadata like:

```json
{
  "type": "equation",
  "equation_id": "eq3",
  "linked_section": "Methods",
  "symbols": ["u_t", "N[u]"],
  "meaning": "Governing equation for forward problem"
}
```

This lets the system **reason over math** — not just regurgitate it.


### 2. Structural Ambiguity → **Semantic Chunking**

Instead of blind chunking, the document is parsed into **section-tagged blocks**:

* Abstract
* Assumptions
* Training Details
* Results (with figures)
* Each Equation separately parsed and linked

During retrieval, the system can **filter by section or content type**.

For example:

> “Show me all assumptions used in the method section”
> …retrieves only semantically relevant content, improving both LLM context and faithfulness.

### 3. Fragmented Reasoning → **Multi-Step Planning**

Agentic RAG uses an **Orchestrator Agent** that:

* Accepts the user query
* Plans which sub-agents to invoke
* Tracks what has been found and what’s missing
* Refines sub-queries and updates memory

This enables multi-hop workflows like:

1. Find relevant loss function
2. Check optimizer details
3. Search for training result comparison
4. Summarize reasons for optimizer choice

Each agent thinks in its own space and reports back.

The final answer isn’t a flat blob — it’s **assembled from structured steps**.

### 4. No Comparison Logic → **ComparerAgent + SynthesizerAgent**

Comparison is hard. It requires:

* Normalizing terminology across papers
* Aligning metrics or assumptions
* Presenting differences clearly

Agentic RAG solves this by:

* Assigning a `ComparerAgent` to find contrast points
* Using a `SynthesizerAgent` to write structured comparative summaries
* Optionally, triggering a `CritiqueAgent` to point out inconsistencies or limitations

For example:

> “How does the loss in XPINN differ from vanilla PINN?”

You get a table like:

| Aspect                | PINN                  | XPINN                  |
| --------------------- | --------------------- | ---------------------- |
| Loss Form             | Collocation loss only | Domain-decomposed loss |
| Parallelism           | No                    | Yes                    |
| Equation Partitioning | Not supported         | Spatially partitioned  |

You can’t do that with vanilla RAG — but agents can.

## 🎯 Final Thoughts

Classic RAG gave us a powerful baseline — one that democratized access to domain knowledge.

But for scientific domains, it's no longer enough. We need systems that can:

* Parse symbols
* Respect structure
* Think in steps
* Compare, critique, and synthesize

That’s what Agentic RAG delivers.

If you're working with technical content — research PDFs, scientific libraries, or mathematical models — this shift is not just helpful. It’s necessary.
